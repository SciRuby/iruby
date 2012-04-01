//----------------------------------------------------------------------------
//  Copyright (C) 2008-2011  The IPython Development Team
//
//  Distributed under the terms of the BSD License.  The full license is in
//  the file COPYING, distributed as part of this software.
//----------------------------------------------------------------------------

//============================================================================
// On document ready
//============================================================================

$(document).ready(function () {
    //IRuby.init_mathjax();

    IRuby.read_only = $('body').data('readOnly') === 'True';
    $('div#main_app').addClass('border-box-sizing ui-widget');
    $('div#notebook_panel').addClass('border-box-sizing ui-widget');
    // The header's bottom border is provided by the menu bar so we remove it.
    $('div#header').css('border-bottom-style','none');

    IRuby.page = new IRuby.Page();
    IRuby.markdown_converter = new Markdown.Converter();
    IRuby.layout_manager = new IRuby.LayoutManager();
    IRuby.pager = new IRuby.Pager('div#pager', 'div#pager_splitter');
    //IRuby.quick_help = new IRuby.QuickHelp('span#quick_help_area');
    //IRuby.login_widget = new IRuby.LoginWidget('span#login_widget');
    IRuby.notebook = new IRuby.Notebook('div#notebook');
    IRuby.save_widget = new IRuby.SaveWidget('span#save_widget');
    IRuby.menubar = new IRuby.MenuBar('#menubar')
    IRuby.toolbar = new IRuby.ToolBar('#toolbar')
    IRuby.notification_widget = new IRuby.NotificationWidget('#notification')

    IRuby.layout_manager.do_resize();

    if(IRuby.read_only){
        // hide various elements from read-only view
        $('div#pager').remove();
        $('div#pager_splitter').remove();

        // set the notebook name field as not modifiable
        $('#notebook_name').attr('disabled','disabled')
    }

    IRuby.page.show();

    IRuby.layout_manager.do_resize();
    $([IRuby.events]).on('notebook_loaded.Notebook', function () {
        IRuby.layout_manager.do_resize();
        IRuby.save_widget.update_url();
    })
    IRuby.notebook.load_notebook($('body').data('notebookId'));
});
