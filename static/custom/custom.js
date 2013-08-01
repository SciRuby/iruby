/* Placeholder for custom JS */
$(function() {
  console.log("IRuby profile loaded")

  // load CodeMirror mode for Ruby
  $.getScript('/static/components/codemirror/mode/ruby/ruby.js');
  IPython.CodeCell.options_default["cm_config"]["mode"] = "ruby";
});
