// Ruby kernel.js

define(['base/js/namespace'], function(IPython) {
    "use strict";
    var onload = function() {
	IPython.CodeCell.options_default['cm_config']['indentUnit'] = 2;
	var cells = IPython.notebook.get_cells();
        for (var i in cells){
            var c = cells[i];
            if (c.cell_type === 'code')
                c.code_mirror.setOption('indentUnit', 2);
        }
    }
    return {onload:onload};
});
