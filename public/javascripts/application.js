// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

/**
 * Sets the value of a select element.
 */
function set_select(el, val) {
	for(var i = 0; i < $(el).options.length; i++) {
		if($(el).options[i].value == val) {
			$(el).selectedIndex = i;
			return;
		}
	}
}