//----------------------------------------------------------------------------
//  Copyright (C) 2008-2011  The IPython Development Team
//
//  Distributed under the terms of the BSD License.  The full license is in
//  the file COPYING, distributed as part of this software.
//----------------------------------------------------------------------------

//============================================================================
// MenuBar
//============================================================================

var IRuby = (function (IRuby) {

    var MenuBar = function (selector) {
        this.selector = selector;
        if (this.selector !== undefined) {
            this.element = $(selector);
            this.style();
            this.bind_events();
        }
    };


    MenuBar.prototype.style = function () {
        this.element.addClass('border-box-sizing');
        $('ul#menus').menubar({
            select : function (event, ui) {
                // The selected cell loses focus when the menu is entered, so we
                // re-select it upon selection.
                var i = IRuby.notebook.get_selected_index();
                IRuby.notebook.select(i);
            }
        });
    };


    MenuBar.prototype.bind_events = function () {
        //  File
        this.element.find('#new_notebook').click(function () {
            window.open($('body').data('baseProjectUrl')+'new');
        });
        this.element.find('#open_notebook').click(function () {
            window.open($('body').data('baseProjectUrl'));
        });
        this.element.find('#rename_notebook').click(function () {
            IRuby.save_widget.rename_notebook();
        });
        this.element.find('#copy_notebook').click(function () {
            var notebook_id = IRuby.notebook.get_notebook_id();
            var url = $('body').data('baseProjectUrl') + notebook_id + '/copy';
            window.open(url,'_newtab');
        });
        this.element.find('#save_notebook').click(function () {
            IRuby.notebook.save_notebook();
        });
        this.element.find('#download_ipynb').click(function () {
            var notebook_id = IRuby.notebook.get_notebook_id();
            var url = $('body').data('baseProjectUrl') + 'notebooks/' +
                      notebook_id + '?format=json';
            window.open(url,'_newtab');
        });
        this.element.find('#download_py').click(function () {
            var notebook_id = IRuby.notebook.get_notebook_id();
            var url = $('body').data('baseProjectUrl') + 'notebooks/' +
                      notebook_id + '?format=py';
            window.open(url,'_newtab');
        });
        this.element.find('button#print_notebook').click(function () {
            IRuby.print_widget.print_notebook();
        });
        // Edit
        this.element.find('#cut_cell').click(function () {
            IRuby.notebook.cut_cell();
        });
        this.element.find('#copy_cell').click(function () {
            IRuby.notebook.copy_cell();
        });
        this.element.find('#delete_cell').click(function () {
            IRuby.notebook.delete_cell();
        });
        this.element.find('#split_cell').click(function () {
            IRuby.notebook.split_cell();
        });
        this.element.find('#merge_cell_above').click(function () {
            IRuby.notebook.merge_cell_above();
        });
        this.element.find('#merge_cell_below').click(function () {
            IRuby.notebook.merge_cell_below();
        });
        this.element.find('#move_cell_up').click(function () {
            IRuby.notebook.move_cell_up();
        });
        this.element.find('#move_cell_down').click(function () {
            IRuby.notebook.move_cell_down();
        });
        this.element.find('#select_previous').click(function () {
            IRuby.notebook.select_prev();
        });
        this.element.find('#select_next').click(function () {
            IRuby.notebook.select_next();
        });
        // View
        this.element.find('#toggle_header').click(function () {
            $('div#header').toggle();
            IRuby.layout_manager.do_resize();
        });
        this.element.find('#toggle_toolbar').click(function () {
            IRuby.toolbar.toggle();
        });
        // Insert
        this.element.find('#insert_cell_above').click(function () {
            IRuby.notebook.insert_cell_above('code');
        });
        this.element.find('#insert_cell_below').click(function () {
            IRuby.notebook.insert_cell_below('code');
        });
        // Cell
        this.element.find('#run_cell').click(function () {
            IRuby.notebook.execute_selected_cell();
        });
        this.element.find('#run_cell_in_place').click(function () {
            IRuby.notebook.execute_selected_cell({terminal:true});
        });
        this.element.find('#run_all_cells').click(function () {
            IRuby.notebook.execute_all_cells();
        });
        this.element.find('#to_code').click(function () {
            IRuby.notebook.to_code();
        });
        this.element.find('#to_markdown').click(function () {
            IRuby.notebook.to_markdown();
        });
        this.element.find('#to_plaintext').click(function () {
            IRuby.notebook.to_plaintext();
        });
        this.element.find('#to_heading1').click(function () {
            IRuby.notebook.to_heading(undefined, 1);
        });
        this.element.find('#to_heading2').click(function () {
            IRuby.notebook.to_heading(undefined, 2);
        });
        this.element.find('#to_heading3').click(function () {
            IRuby.notebook.to_heading(undefined, 3);
        });
        this.element.find('#to_heading4').click(function () {
            IRuby.notebook.to_heading(undefined, 4);
        });
        this.element.find('#to_heading5').click(function () {
            IRuby.notebook.to_heading(undefined, 5);
        });
        this.element.find('#to_heading6').click(function () {
            IRuby.notebook.to_heading(undefined, 6);
        });
        this.element.find('#toggle_output').click(function () {
            IRuby.notebook.toggle_output();
        });
        this.element.find('#clear_all_output').click(function () {
            IRuby.notebook.clear_all_output();
        });
        // Kernel
        this.element.find('#int_kernel').click(function () {
            IRuby.notebook.kernel.interrupt();
        });
        this.element.find('#restart_kernel').click(function () {
            IRuby.notebook.restart_kernel();
        });
        // Help
        this.element.find('#keyboard_shortcuts').click(function () {
            IRuby.quick_help.show_keyboard_shortcuts();
        });
    };


    IRuby.MenuBar = MenuBar;

    return IRuby;

}(IRuby));
