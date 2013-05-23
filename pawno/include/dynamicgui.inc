#if defined __dynamicgui
	#endinput
#endif
#define __dynamicgui

//  DynamicGui v0.1 by Tomasz Ptak (promsters a.k.a iBored) //
// native DynamicGui_Init()
// native DynamicGui_FormatRow(pattern[], params...) -- acts like format()
// native DynamicGui_AddBlankRow(name[])
// native DynamicGui_AddRow(value, additional_data_int=0)
// native DynamicGui_FreeRow() -- internal use
// native DynamicGui_Build()
// native DynamicGui_GetValue(listitem)
// native DynamicGui_GetDataInt(listitem)


#define DYNAMIC_GUI_MAX_ROWS 20  // Max rows in gui
#define DYNAMIC_GUI_ROW_SIZE 100 // String size per one gui row

#define DG_NO_ACTION 0  // Value of no action row
#define INVALID_ROW_VALUE -198744124 // Do not touch

enum e_dynamic_gui_row
{
	value,
	additional_data_int,
}
new dynamic_gui[DYNAMIC_GUI_MAX_ROWS][e_dynamic_gui_row];

new dynamic_gui_string[DYNAMIC_GUI_MAX_ROWS*DYNAMIC_GUI_ROW_SIZE];
new dynamic_gui_temp_row[DYNAMIC_GUI_ROW_SIZE];

#define DynamicGui_FormatRow(%1,%2) format(dynamic_gui_temp_row,sizeof(dynamic_gui_temp_row),%1,%2)

#define DynamicGui_AddBlankRowFormat(%1,%2) format(dynamic_gui_temp_row,sizeof(dynamic_gui_temp_row),%1,%2); DynamicGui_AddBlankRow(dynamic_gui_temp_row)

stock DynamicGui_Init()
{
	for(new i; i < DYNAMIC_GUI_MAX_ROWS; i++)
	{
		dynamic_gui[i][value] = INVALID_ROW_VALUE;
		dynamic_gui[i][additional_data_int] = 0;
	}
	
	format(dynamic_gui_string, sizeof(dynamic_gui_string), "");
}

stock DynamicGui_FreeRow()
{
	for(new i; i < DYNAMIC_GUI_MAX_ROWS; i++)
	{
		if( dynamic_gui[i][value] == INVALID_ROW_VALUE )
		{
			return i;
		}
	}
	
	return -1;
}

stock DynamicGui_AddRow(dg_value, dg_additional_data_int = 0)
{
	new first_free_row = DynamicGui_FreeRow();
	if( first_free_row == -1 ) return;

	format(dynamic_gui_string, sizeof(dynamic_gui_string), "%s%s\n", dynamic_gui_string, dynamic_gui_temp_row);

	dynamic_gui[first_free_row][value] = dg_value;
	dynamic_gui[first_free_row][additional_data_int] = dg_additional_data_int;
	
	format(dynamic_gui_temp_row, sizeof(dynamic_gui_temp_row), "");
}

stock DynamicGui_AddBlankRow(dg_name[])
{
	new first_free_row = DynamicGui_FreeRow();
	if( first_free_row == -1 ) return;

	format(dynamic_gui_string, sizeof(dynamic_gui_string), "%s%s\n", dynamic_gui_string, dg_name);

	dynamic_gui[first_free_row][value] = DG_NO_ACTION;
}

stock DynamicGui_Build()
{
	return _:dynamic_gui_string;
}

stock DynamicGui_GetValue(listitem)
{
	if( listitem > DYNAMIC_GUI_MAX_ROWS-1 ) return 0;
	
	return dynamic_gui[listitem][value];
}

stock DynamicGui_GetDataInt(listitem)
{
	if( listitem > DYNAMIC_GUI_MAX_ROWS-1 ) return 0;
	
	return dynamic_gui[listitem][additional_data_int];
}