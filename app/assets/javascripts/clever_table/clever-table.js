$(function () {
  function queryMode() {
    return $('thead').hasClass('querying')
  }

  function instrumentTable(i, tbl) {
    $(tbl).find('th[data-col]').click(headClick)
  }

  function headClick(evt) {
    if (!queryMode()) {
      var target = evt.target;
      var col    = $(target).data('col');
      doSort(col)
    }
  }

  function doSort(col) {
    function getSort(col) {
      if ($.query.get('sort') == col) {
        var direction = $.query.get('dir');
        newDirection  = direction == 'asc' ? 'desc' : 'asc';

        return newDirection
      } else {
        return 'asc'
      }
    }

    var dir       = getSort(col);
    location.href = $.query.set('dir', dir).set('sort', col).remove('before').remove('after').set('page', 1).toString()
  }

  $('.clever-table').each(instrumentTable);


  var queryDiv = $('#query-content');

  function findMenuIndex(elt, value) {
    var options = elt.options;
    var l       = options.length;
    for (var i = 0; i < l; i++) {
      if (options[i].value == value) {
        return i
      }
    }
    return null
  }

  function showQueryUI(col, type, operator, args, text) {
    function setFormHandler(ui, col) {
      $(ui).submit(function (evt) {
        evt.preventDefault();
        updateArgs(ui, col)
      })
    }

    function getQueryUI(type) {
      return $('#query-templates form.query-' + type).clone()
    }

    function updateArgs(ui, col) {
      var operator   = $(ui).find('[name=operator]').val();
      var argControl = $(ui).find('[name=arg]');
      if (argControl.attr('type')) {
        //This is a regular input
        var arg = argControl.val()
      } else {
        //This is a popup
        var arg = argControl.find(':selected').text().toLowerCase().replace(' ', '_')
      }
      var newURL = $.query.set(col + '_' + operator, arg);
      location   = newURL
    }

    function setPopupByValue(elt, value) {
      var menu = $(elt).find('select')[0];
      var indx = findMenuIndex(menu, value);
      if (indx) {
        menu.selectedIndex = indx
      }
    }

    function setPopupByText(elt, text) {
      var options = elt.children('option');
      options.each(function (i, opt) {
        if (opt.text.toLowerCase().replace(' ', '_') === text) {
          elt.val(i)
        }
      })
    }

    function setFieldName(elt, col) {
      $(elt).find('.col').html(col)
    }

    function sharedInit(elt, col, operator, args, text) {
      setPopupByValue(elt, operator);
      setFieldName(elt, text)
    }

    function setArg(elt, arg) {
      $(elt).find('input[name=arg]').val(arg)
    }

    function getQueryValue(col, op) {
      return $.query.get(col + '_' + op)
    }


    function manageBetween(elt, ui, text, col) {
      function operatorChanged(evt) {
        var popup = elt.find('[name=operator]');
        var popupSelection = popup.val();
        if (/\(betw\)/.test(popup.find(':selected').text())) {
          var arg = elt.find('[name=arg]');
          arg.replaceWith(ui);
          setFormHandler(ui, col)
        } else if (elt.find('.between')){
          var eltClass = /query-(\S*)/.exec(elt.attr('class'))[1];
          var newElt = getQueryUI(eltClass);
          elt.replaceWith(newElt);
          elt = newElt;
          setFieldName(elt, text);
          popup = elt.find('[name=operator]');
          popup.change(operatorChanged);
          popup.val(popupSelection);
          setFormHandler(newElt, col)
        }
      }

      elt.find('[name=operator]').change(operatorChanged)
    }

    var initFunctions = {
      integer: function (elt, col, operator, args, text) {
        sharedInit(elt, col, operator, args, text);
        manageBetween((elt), $('.numeric-between'), text, col);
        setArg(elt, getQueryValue(col, operator))
      },
      datetime: function (elt, col, operator, args, text) {
        sharedInit(elt, col, operator, args, text);
        manageBetween(elt, $('.date-between'), text, col);
        elt.find('input').val(getQueryValue(col, operator))
      },
      string: function (elt, col, operator, args, text) {
        sharedInit(elt, col, operator, args, text);
        setArg(elt, getQueryValue(col, operator))
      },
      text: function (elt, col, operator, args, text) {
        sharedInit(elt, col, operator, args, text);
        setArg(elt, getQueryValue(col, operator))
      },
      list: function (elt, col, operator, args, text) {
        setFieldName(elt, text);
        var header   = $('th[data-col=' + col + ']');
        var listArgs = header.data('list-args');
        var options  = elt.find('select');
        for (key in listArgs) {
          options.append($('<option>', {value: key}).text(listArgs[key]))
        }

        setPopupByText(elt.find('select'), getQueryValue(col, operator))
      }
    };

    //showQueryUI function body
    var ui       = getQueryUI(type);
    var queryDiv = $('#query-content');

    queryDiv.empty();
    queryDiv.append(ui);

    initFunctions[type](ui, col, operator, args, text);
    setFormHandler(ui, col)

  }

  function getOperation(query, col) {
    var opMatcher = new RegExp(col + '_' + '(.+)');
    var result, value;

    $.each(query, function (k, v) {
      m = k.match(opMatcher);
      if (m) {
        result = m;
        value  = v;
        return false
      }
    });

    if (result) {
      return [result[1], value]
    }

    return null
  }

  function queryHeadClick(evt) {
    var target = $(evt.target);
    var text   = evt.target.innerHTML;
    var col    = target.data('col');
    var type   = target.data('type');

    var query     = $.query.get();
    var operation = getOperation(query, col);
    if (operation) {
      var operator = operation[0];
      var arg      = operation[1]
    } else {
      var operator = null;
      var arg      = null
    }

    showQueryUI(col, type, operator, arg, text)
  }

  function instrumentHeader(elt) {
    elt.click(queryHeadClick)
  }

  function activateQueryUI() {
    instrumentHeader($('table.clever-table th'));
    $('thead').addClass('querying')
  }

  function deactivateQueryUI() {
    $('table.clever-table th').unbind('click', queryHeadClick);
    $('thead').removeClass('querying')
  }

  function handleUnconstrains() {
    $('.unconstrain').click(function(evt) {
      var op = $(evt.target).data('col');
      location.search = $.query.remove(op).toString()
    })
  }

  $('#query-button').click(function () {
    queryDiv.toggle({duration: 100});
    if (queryMode()) {
      deactivateQueryUI()
    } else {
      activateQueryUI()
    }
  });

  handleUnconstrains()
});
