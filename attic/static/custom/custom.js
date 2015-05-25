$([IPython.events]).on('notebook_loaded.Notebook', function(){
    // add here logic that should be run once per **notebook load**
    IPython.notebook.metadata.language = 'ruby' ;
});

$([IPython.events]).on('app_initialized.NotebookApp', function(){
    // add here logic that shoudl be run once per **page load**
    CodeMirror.requireMode('ruby', function(){
         console.log('Ruby mode should now be available in codemirror.');
    })
    IPython.CodeCell.options_default['cm_config']['mode'] = 'ruby';
    IPython.CodeCell.options_default['cm_config']['indentUnit'] = 2;
});

document.title = document.title.replace('IPython', 'IRuby');
