// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

// handles fields w/ specific preloaded text that must be greyed out
function processPreloadedText(field, event, defaultText)
{
	if(event == 'onfocus')
	{
		if(field.value == defaultText)
		{
			field.value = '';
			field.removeClassName('inactive_preloaded_field');
			field.addClassName('active_preloaded_field');
		}
	}
	else if(event == 'onblur')
	{
		if(field.value == '')
		{
			field.value = defaultText;
			field.addClassName('inactive_preloaded_field');
			field.removeClassName('active_preloaded_field');
		}
	}
}