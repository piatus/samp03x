#define FILTERSCRIPT
#define VERSION_STR "v0.1"

#include <a_samp>
#include <zcmd>
#include <djson>
#include <sscanf2>

#define MAX_LABELS 1000

new colors[] = { 0xFF0000FF, 0x009D00FF, 0x0000FFFF, 0x000000FF, 0xFFFF00FF, 0xFF8000FF, 0x0080FFFF, 0x800080FF, 0xFFFFFFFF };

enum e_labels
{
	label_text[200],
	label_color,
	Float:label_x,
	Float:label_y,
	Float:label_z,
	label_vw,
	label_los,
	label_state,
	Float:label_draw
}
new Label[Text3D:MAX_LABELS][e_labels];

enum e_sortlabels
{
	label_id,
	Float:label_distance
}
new LabelSort[MAX_PLAYERS][MAX_LABELS][e_sortlabels];

new Edited[MAX_PLAYERS];
new EditedObject[MAX_PLAYERS];

#define LABEL_STATE_VISIBLE 5

#define COLOR_GAY 0xFF2291FF

#define DIALOG_3DL 1996
#define DIALOG_3DL_CREATE 19961
#define DIALOG_3DL_CREATE_FINISH 19962
#define DIALOG_3DL_REMOVE 19963
#define DIALOG_3DL_REMOVE_NO 19964
#define DIALOG_3DL_EDIT_LIST 19965
#define DIALOG_3DL_EDIT 19966
#define DIALOG_3DL_EDIT_TEXT 19967
#define DIALOG_3DL_EDIT_COLOR 19968
#define DIALOG_3DL_EDIT_COLOR_INPUT 19969
#define DIALOG_3DL_EDIT_COLOR_LIST 19970
#define DIALOG_3DL_EDIT_DRAW 19971
#define DIALOG_3DL_EXPORT 19972

public OnFilterScriptInit()
{
	djson_GameModeInit();
	if( djIsSet("3dl.json", "label") )
	{
		new t1 = GetTickCount();
		new tmp[30], count;
		
		for (new i; i < djCount("3dl.json","label"); i++)
		{
			format(tmp, sizeof(tmp), "label/%d", i);
			sscanf(dj("3dl.json",tmp), "p<;>s[200]dfffdfd", Label[Text3D:i][label_text], Label[Text3D:i][label_color], Label[Text3D:i][label_x], Label[Text3D:i][label_y], Label[Text3D:i][label_z], Label[Text3D:i][label_vw], Label[Text3D:i][label_draw], Label[Text3D:i][label_los]);
			Label[Text3D:i][label_state] = LABEL_STATE_VISIBLE;
			
			Create3DTextLabel(Labels_GetText(i), Label[Text3D:i][label_color], Label[Text3D:i][label_x], Label[Text3D:i][label_y], Label[Text3D:i][label_z], Label[Text3D:i][label_draw], Label[Text3D:i][label_vw], Label[Text3D:i][label_los]);
			count++;
		}
		printf("[3dl][load] Loaded saved 3d text labels. [Count: %d] [Time: %dms]", count, GetTickCount()-t1);
	}
	
	for(new i; i < MAX_PLAYERS; i++)
	{
		if( !IsPlayerConnected(i) ) continue;
		Edited[i] = -1;
		EditedObject[i] = -1;
	}
	
	print("[3dl] 3DL "VERSION_STR" filterscript loaded. [Author: Tomasz Ptak a.k.a promsters]");
	return 1;
}

public OnFilterScriptExit()
{
	for(new i; i < MAX_LABELS; i++)
	{
		format(Label[Text3D:i][label_text], 200, "");
		Label[Text3D:i][label_color] = 0;
		Label[Text3D:i][label_x] = 0.0;
		Label[Text3D:i][label_y] = 0.0;
		Label[Text3D:i][label_z] = 0.0;
		Label[Text3D:i][label_vw] = 0;
		Label[Text3D:i][label_state] = 0;
		Label[Text3D:i][label_los] = 0;
		Label[Text3D:i][label_draw] = 0.0;
		
		Delete3DTextLabel(Text3D:i);
	}
	
	djson_GameModeExit();
}

public OnPlayerSpawn(playerid)
{
	SendClientMessage(playerid, COLOR_GAY, "Use /3dl to access 3d label creation menu."); 
	
	Edited[playerid] = -1;
	EditedObject[playerid] = -1;
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch( dialogid )
	{
		case DIALOG_3DL:
		{
			if( !response ) return 1;
			
			if( listitem == 0 ) return ShowPlayerDialog(playerid, DIALOG_3DL_CREATE, DIALOG_STYLE_INPUT, "3DL » Create new label [1/2]", "Type 3d label text below (you can change it later):", "Next", "Back");
			if( listitem == 1 )
			{
				ShowNearestLabels(playerid, DIALOG_3DL_EDIT_LIST, DIALOG_3DL_REMOVE_NO);
				return 1;
			}
			if( listitem == 2 )
			{
				ShowNearestLabels(playerid, DIALOG_3DL_REMOVE, DIALOG_3DL_REMOVE_NO);
				return 1;
			}
			if( listitem == 3 )
			{
				ShowPlayerDialog(playerid, DIALOG_3DL_EXPORT, DIALOG_STYLE_LIST, "3DL » Export labels", "» Export for standard SA-MP Create3DTextLabel()\n» Export for Incognito's streamer CreateDynamic3DTextLabel()", "Next", "Back");
				return 1;
			}
		}
		
		case DIALOG_3DL_CREATE:
		{
			if( !response ) return cmd_3dl(playerid, "");
			
			if( isnull(inputtext) ) return ShowPlayerDialog(playerid, DIALOG_3DL_CREATE, DIALOG_STYLE_INPUT, "3DL » Create new label [1/2]", "{FF3C3C}Text cannot be empty.\n{A9C4E4}Type 3d label text below (you can change it later):", "Next", "Back");
			
			new 
				Float: Pos[3];
			GetPlayerPos(playerid, Pos[0], Pos[1], Pos[2]);
			GetXYInFrontOfPlayer(playerid, Pos[0], Pos[1], 2.5);
			
			new Text3D:tmpid = Create3DTextLabel(inputtext, 0xFFFFFFFF, Pos[0], Pos[1], Pos[2], 50.0, GetPlayerVirtualWorld(playerid));	
			format(Label[tmpid][label_text], 200, inputtext);
			Label[tmpid][label_color] = 0xFFFFFFFF;
			Label[tmpid][label_x] = Pos[0];
			Label[tmpid][label_y] = Pos[1];
			Label[tmpid][label_z] = Pos[2];
			Label[tmpid][label_vw] = GetPlayerVirtualWorld(playerid);
			Label[tmpid][label_draw] = 50.0;
			Label[tmpid][label_los] = 0;
			Label[tmpid][label_state] = LABEL_STATE_VISIBLE;
			
			Labels_Save(_:tmpid);
			Update3DTextLabelText(tmpid, 0xFFFFFFFF, Labels_GetText(_:tmpid));
			
			ShowPlayerDialog(playerid, DIALOG_3DL_CREATE_FINISH, DIALOG_STYLE_MSGBOX, "3DL » Create new label [2/2]", "3d text label was created successfully. Press 'Finish' to open label edit window.\n\nWhat can you do now?\n\t• Change position of the label\n\t• Change color\n\t• Change text\n\t• Attach to vehicle or player", "Finish", "");
		}
		
		case DIALOG_3DL_CREATE_FINISH:
		{
			if( !response ) return 1;
		}
		
		case DIALOG_3DL_REMOVE_NO:
		{
			return cmd_3dl(playerid, "");
		}
		
		case DIALOG_3DL_REMOVE:
		{
			if( !response ) return cmd_3dl(playerid, "");
			
			new tmp[20], index = LabelSort[playerid][listitem][label_id]; 
			Delete3DTextLabel(Text3D:index);
			Label[Text3D:index][label_state] = 0;
			format(tmp, sizeof(tmp), "label/%d", index);
			djUnset("3dl.json", tmp);
			
			SendClientMessage(playerid, COLOR_GAY, "3DL: 3d text label was successfully removed.");
			
			ShowNearestLabels(playerid, DIALOG_3DL_REMOVE, DIALOG_3DL_REMOVE_NO);
		}
		
		case DIALOG_3DL_EDIT_LIST:
		{
			if( !response ) return cmd_3dl(playerid, "");
			
			Edited[playerid] = LabelSort[playerid][listitem][label_id];
			ShowLabelEdit(playerid, Edited[playerid]);
		}
		
		case DIALOG_3DL_EDIT:
		{
			if( !response ) return cmd_3dl(playerid, "");
			
			new 
				tmp[40],
				capt[70];
			strmid(tmp, Label[Text3D:Edited[playerid]][label_text], 0, 40);
			format(capt, sizeof(capt), "3DL » Edit: %s", tmp);
			
			if( listitem == 0 )
			{
				ShowPlayerDialog(playerid, DIALOG_3DL_EDIT_TEXT, DIALOG_STYLE_INPUT, capt, "Input new text string below (remember that you can use embedded colors and \\n for new line):", "Change", "Back");
			}
			else if( listitem == 1 )
			{
				Delete3DTextLabel(Text3D:Edited[playerid]);
				
				EditedObject[playerid] = CreateObject(1455, Label[Text3D:Edited[playerid]][label_x], Label[Text3D:Edited[playerid]][label_y], Label[Text3D:Edited[playerid]][label_z], 0.0, 0.0, 0.0, 50.0);
				EditObject(playerid, EditedObject[playerid]);
			}
			else if( listitem == 2 )
			{
				ShowPlayerDialog(playerid, DIALOG_3DL_EDIT_COLOR, DIALOG_STYLE_LIST, capt, "Input your own hex color\nSelect premade color", "Choose", "Back");
			}
			else if( listitem == 3 )
			{
				ShowPlayerDialog(playerid, DIALOG_3DL_EDIT_DRAW, DIALOG_STYLE_INPUT, capt, "Input new draw distance for this 3d text label:", "Change", "Back");
			}
			else if( listitem == 5 )
			{
				if( Label[Text3D:Edited[playerid]][label_los] ) Label[Text3D:Edited[playerid]][label_los] = 0;
				else if( !Label[Text3D:Edited[playerid]][label_los] ) Label[Text3D:Edited[playerid]][label_los] = 1;
				
				Labels_Save(Edited[playerid]);
				Labels_Update(Edited[playerid]);
			
				SendClientMessage(playerid, COLOR_GAY, "3DL: 3d text label line of sight test was successfully changed.");
				ShowLabelEdit(playerid, Edited[playerid]);
			}
			
		}
		
		case DIALOG_3DL_EDIT_TEXT:
		{
			if( !response ) return ShowLabelEdit(playerid, Edited[playerid]);
			
			new 
				tmp[40],
				capt[70];
			strmid(tmp, Label[Text3D:Edited[playerid]][label_text], 0, 40);
			format(capt, sizeof(capt), "3DL » Edit: %s", tmp);
			
			if( isnull(inputtext) )
			{
				ShowPlayerDialog(playerid, DIALOG_3DL_EDIT_TEXT, DIALOG_STYLE_INPUT, capt, "{FF3C3C}Text cannot be empty.\n{A9C4E4}Input new text string below (remember that you can use embedded colors and \\n for new line):", "Change", "Back");
			}
			else
			{
				format(Label[Text3D:Edited[playerid]][label_text], 200, inputtext);
				Update3DTextLabelText(Text3D:Edited[playerid], Label[Text3D:Edited[playerid]][label_color], Labels_GetText(Edited[playerid]));
				
				Labels_Save(Edited[playerid]);
				
				SendClientMessage(playerid, COLOR_GAY, "3DL: 3d text label text string was successfully changed.");
				ShowLabelEdit(playerid, Edited[playerid]);
			}
		}
		
		case DIALOG_3DL_EDIT_COLOR:
		{
			if( !response ) return ShowLabelEdit(playerid, Edited[playerid]);
			
			new 
				tmp[40],
				capt[70];
			strmid(tmp, Label[Text3D:Edited[playerid]][label_text], 0, 40);
			format(capt, sizeof(capt), "3DL » Edit: %s", tmp);
			
			if( listitem == 0 )
			{
				ShowPlayerDialog(playerid, DIALOG_3DL_EDIT_COLOR_INPUT, DIALOG_STYLE_INPUT, capt, "Input hex color below (ex. 0xFFFFFFFF, 8 digits RGBA):", "Change", "Back");
			}
			else if( listitem == 1 )
			{
				ShowPlayerDialog(playerid, DIALOG_3DL_EDIT_COLOR_LIST, DIALOG_STYLE_LIST, capt, "Red\nGreen\nBlue\nBlack\nYellow\nOrange\nLight blue\nPurple\nWhite", "Change", "Back");
			}
		}
		
		case DIALOG_3DL_EDIT_COLOR_INPUT:
		{
			new 
				tmp[40],
				capt[70];
			strmid(tmp, Label[Text3D:Edited[playerid]][label_text], 0, 40);
			format(capt, sizeof(capt), "3DL » Edit: %s", tmp);
			
			if( !response ) return ShowPlayerDialog(playerid, DIALOG_3DL_EDIT_COLOR, DIALOG_STYLE_LIST, capt, "Input your own hex color\nSelect premade color", "Choose", "Back");
			
			new color;
			if( sscanf(inputtext, "h", color) )
			{
				return ShowPlayerDialog(playerid, DIALOG_3DL_EDIT_COLOR_INPUT, DIALOG_STYLE_INPUT, capt, "{FF3C3C}Wrong color format.\n{A9C4E4}Input hex color below (ex. 0xFFFFFFFF, 8 digits RGBA):", "Change", "Back");
			}

			Label[Text3D:Edited[playerid]][label_color] = color;
			Update3DTextLabelText(Text3D:Edited[playerid], Label[Text3D:Edited[playerid]][label_color], Labels_GetText(Edited[playerid]));		
			Labels_Save(Edited[playerid]);
				
			SendClientMessage(playerid, COLOR_GAY, "3DL: 3d text label color was successfully changed.");
			ShowLabelEdit(playerid, Edited[playerid]);
		}
		
		case DIALOG_3DL_EDIT_COLOR_LIST:
		{
			new 
				tmp[40],
				capt[70];
			strmid(tmp, Label[Text3D:Edited[playerid]][label_text], 0, 40);
			format(capt, sizeof(capt), "3DL » Edit: %s", tmp);
			
			if( !response ) return ShowPlayerDialog(playerid, DIALOG_3DL_EDIT_COLOR, DIALOG_STYLE_LIST, capt, "Input your own hex color\nSelect premade color", "Choose", "Back");
			
			Label[Text3D:Edited[playerid]][label_color] = colors[listitem];
			Update3DTextLabelText(Text3D:Edited[playerid], Label[Text3D:Edited[playerid]][label_color], Labels_GetText(Edited[playerid]));		
			Labels_Save(Edited[playerid]);
				
			SendClientMessage(playerid, COLOR_GAY, "3DL: 3d text label color was successfully changed.");
			ShowLabelEdit(playerid, Edited[playerid]);
		}
		
		case DIALOG_3DL_EDIT_DRAW:
		{
			if( !response ) return ShowLabelEdit(playerid, Edited[playerid]);
			new 
				tmp[40],
				capt[70];
			strmid(tmp, Label[Text3D:Edited[playerid]][label_text], 0, 40);
			format(capt, sizeof(capt), "3DL » Edit: %s", tmp);

			if( sscanf(inputtext, "f", Label[Text3D:Edited[playerid]][label_draw]) )
			{
				return ShowPlayerDialog(playerid, DIALOG_3DL_EDIT_COLOR_INPUT, DIALOG_STYLE_INPUT, capt, "{FF3C3C}Wrong draw distance value.\n{A9C4E4}Input new draw distance for this 3d text label:", "Change", "Back");
			}
			
			Labels_Save(Edited[playerid]);
			Labels_Update(Edited[playerid]);
			
			SendClientMessage(playerid, COLOR_GAY, "3DL: 3d text label draw distance was successfully changed.");
			ShowLabelEdit(playerid, Edited[playerid]);
		}
		
		case DIALOG_3DL_EXPORT:
		{
			if( !response ) return cmd_3dl(playerid, "");
			
			if( listitem == 0 )
			{
				fremove("3dl_export_standard.txt");
				new 
					string[400], 
					File:ftw = fopen("3dl_export_standard.txt", io_append);
 
				if(ftw)
				{
					for(new i; i < MAX_LABELS; i++)
					{
						if( Label[Text3D:i][label_state] <= 0 ) continue;
						format(string, sizeof(string), "Create3DTextLabel(\"%s\", %d, %f, %f, %f, %f, %d, %d);\r\n", Label[Text3D:i][label_text], Label[Text3D:i][label_color], Label[Text3D:i][label_x], Label[Text3D:i][label_y], Label[Text3D:i][label_z], Label[Text3D:i][label_draw], Label[Text3D:i][label_vw], Label[Text3D:i][label_los]);
						fwrite(ftw, string);
					}
					fclose(ftw);
					
					SendClientMessage(playerid, COLOR_GAY, "3DL: All 3d text labels have been exported to 3dl_export_standard.txt.");
				}
			}
			else if( listitem == 1 )
			{
				fremove("3dl_export_streamer.txt");
				new 
					string[400], 
					File:ftw = fopen("3dl_export_streamer.txt", io_append);
 
				if(ftw)
				{
					for(new i; i < MAX_LABELS; i++)
					{
						if( Label[Text3D:i][label_state] <= 0 ) continue;
						format(string, sizeof(string), "CreateDynamic3DTextLabel(\"%s\", %d, %f, %f, %f, %f, -1, -1, %d, %d);\r\n", Label[Text3D:i][label_text], Label[Text3D:i][label_color], Label[Text3D:i][label_x], Label[Text3D:i][label_y], Label[Text3D:i][label_z], Label[Text3D:i][label_draw], Label[Text3D:i][label_los], Label[Text3D:i][label_vw]);
						fwrite(ftw, string);
					}
					fclose(ftw);
					
					SendClientMessage(playerid, COLOR_GAY, "3DL: All 3d text labels have been exported to 3dl_export_streamer.txt.");
				}
			}
		}
	}
	return 1;
}

public OnPlayerEditObject(playerid, playerobject, objectid, response, Float:fX, Float:fY, Float:fZ, Float:fRotX, Float:fRotY, Float:fRotZ)
{ 
	if( objectid == EditedObject[playerid] && Edited[playerid] > -1 )
	{
		if( response == EDIT_RESPONSE_FINAL )
		{
			Label[Text3D:Edited[playerid]][label_x] = fX;
			Label[Text3D:Edited[playerid]][label_y] = fY;
			Label[Text3D:Edited[playerid]][label_z] = fZ;
			
			DestroyObject(objectid);
			EditedObject[playerid] = -1;
			
			SendClientMessage(playerid, COLOR_GAY, "3DL: 3d text label position was successfully changed.");
			
			Labels_Save(Edited[playerid]);
			Labels_Update(Edited[playerid]);
		
			ShowLabelEdit(playerid, Edited[playerid]);
		}
		
		if( response == EDIT_RESPONSE_CANCEL )
		{
			DestroyObject(objectid);
			EditedObject[playerid] = -1;
			
			SendClientMessage(playerid, COLOR_GAY, "3DL: 3d text label position edition was cancelled.");
			Labels_Update(Edited[playerid]);
			ShowLabelEdit(playerid, Edited[playerid]);
		}
	}
}

COMMAND:3dl(playerid, params[])
{
	if( EditedObject[playerid] > -1 ) return SendClientMessage(playerid, COLOR_GAY, "3DL: ERROR - You cannot access 3dl menu when editing label position.");

	new string[200];
	format(string, sizeof(string), "» Create new label\n» Edit existing label\n» Delete label\n» Export labels\n\t\t\n{FF2291}Created labels: {FFFFFF}%d\n\t\t\t\t\t\t\t{FFFFFF}Written by promsters", Labels_Count());
	ShowPlayerDialog(playerid, DIALOG_3DL, DIALOG_STYLE_LIST, "3DL", string, "Choose", "Close");
	return 1;
}

stock Labels_Count()
{
	new count;
	for(new i; i < MAX_LABELS; i++)
	{
		if( Label[Text3D:i][label_state] > 0 ) count++;
	}
	
	return count;
}

stock Labels_Save(labelid)
{
	new str[20], data[300];
	format(str, sizeof(str), "label/%d", labelid);
	format(data, sizeof(data), "%s;%d;%f;%f;%f;%d;%f;%d", Label[Text3D:labelid][label_text], Label[Text3D:labelid][label_color], Label[Text3D:labelid][label_x], Label[Text3D:labelid][label_y], Label[Text3D:labelid][label_z], Label[Text3D:labelid][label_vw], Label[Text3D:labelid][label_draw], Label[Text3D:labelid][label_los]);
	djSet("3dl.json", str, data);
}

stock Labels_GetText(labelid)
{
	new tmpd[200];
	str_replace("\n", "\\n", Label[Text3D:labelid][label_text], tmpd);
	
	return _:tmpd;
}

stock Labels_Update(labelid)
{
	Delete3DTextLabel(Text3D:labelid);
	
	Create3DTextLabel(Labels_GetText(labelid), Label[Text3D:labelid][label_color], Label[Text3D:labelid][label_x], Label[Text3D:labelid][label_y], Label[Text3D:labelid][label_z], Label[Text3D:labelid][label_draw], Label[Text3D:labelid][label_vw], Label[Text3D:labelid][label_los]);
}

stock ShowNearestLabels(playerid, choose, deny)
{
	new string[700], number;
	for(new i; i < MAX_LABELS; i++) LabelSort[playerid][i][label_id] = -1;
	
	for(new i; i < MAX_LABELS; i++)
	{
		if( Label[Text3D:i][label_state] != LABEL_STATE_VISIBLE ) continue;
		LabelSort[playerid][number][label_id] = i;
		LabelSort[playerid][number][label_distance] = GetPlayerDistanceFromPoint(playerid, Label[Text3D:i][label_x], Label[Text3D:i][label_y], Label[Text3D:i][label_z]);
		number++;
	}
	
	if( number > 0 )
	{
		repeat:
		new changes;
		for(new i; i < MAX_LABELS; i++)
		{
			if( LabelSort[playerid][i][label_id] == -1 || LabelSort[playerid][i+1][label_id] == -1 ) break;
			
			if( LabelSort[playerid][i+1][label_distance] < LabelSort[playerid][i][label_distance] )
			{
				new tid = LabelSort[playerid][i][label_id], Float:tdis = LabelSort[playerid][i][label_distance];
				
				LabelSort[playerid][i][label_distance] = LabelSort[playerid][i+1][label_distance];
				LabelSort[playerid][i][label_id] = LabelSort[playerid][i+1][label_id];
				
				LabelSort[playerid][i+1][label_distance] = tdis;
				LabelSort[playerid][i+1][label_id] = tid;
				
				changes = 1;
			}
		}
		if( changes ) goto repeat;
		for(new i; i < MAX_LABELS; i++)
		{
			if( LabelSort[playerid][i][label_id] == -1 ) break;
			new 
				tmp[40];
			strmid(tmp, Label[Text3D:LabelSort[playerid][i][label_id]][label_text], 0, 40);
			format(string, sizeof(string), "%s\n%d. [%.1fm]\t%s... ", string, i+1, LabelSort[playerid][i][label_distance], tmp);
		}
		
		if( choose == DIALOG_3DL_REMOVE ) ShowPlayerDialog(playerid, choose, DIALOG_STYLE_LIST, "3DL » Deleting 3d text label", string, "Delete", "Back");
		else ShowPlayerDialog(playerid, choose, DIALOG_STYLE_LIST, "3DL » Editing 3d text label", string, "Edit", "Back");
	}
	else
	{
		ShowPlayerDialog(playerid, deny, DIALOG_STYLE_MSGBOX, "3DL » Information", "There are no 3d labels created.", "Back", "");
	}
	
	return 1;
}

stock ShowLabelEdit(playerid, labelid)
{
	new 
		tmp[40],
		capt[70],
		string[300];
	strmid(tmp, Label[Text3D:labelid][label_text], 0, 40);
	format(capt, sizeof(capt), "3DL » Edit: %s", tmp);
	
	format(string, sizeof(string), "» Edit text string\n» Edit position\n» Edit color\n» Edit drawdistance\n\t\t\n» Test LOS: {FF2291}%s {FFFFFF}(click to change)", (Label[Text3D:labelid][label_los]==1) ? ("Yes") : ("No"));
	ShowPlayerDialog(playerid, DIALOG_3DL_EDIT, DIALOG_STYLE_LIST, capt, string, "Choose", "Back");
	return 1;
}

stock GetXYInFrontOfPlayer(playerid,&Float:x,&Float:y,Float:Distance)
{
	new Float:r;
	if( !IsPlayerInAnyVehicle(playerid) ) GetPlayerFacingAngle(playerid,r);
	else GetVehicleZAngle(GetPlayerVehicleID(playerid),r);
	x += (Distance * floatsin(-r, degrees));
	y += (Distance * floatcos(-r, degrees));
	return 1;
}

stock str_replace (newstr [], oldstr [], srcstr [], deststr [], bool: ignorecase = false, size = sizeof (deststr))
{
    new
        newlen = strlen (newstr),
        oldlen = strlen (oldstr),
        srclen = strlen (srcstr),
        idx,
        rep;

    for (new i = 0; i < srclen; ++i)
    {
        if ((i + oldlen) <= srclen)
        {
            if (!strcmp (srcstr [i], oldstr, ignorecase, oldlen))
            {
                deststr [idx] = '\0';
                strcat (deststr, newstr, size);
                ++rep;
                idx += newlen;
                i += oldlen - 1;
            }
            else
            {
                if (idx < (size - 1))
                    deststr [idx++] = srcstr [i];
                else
                    return rep;
            }
        }
        else
        {
            if (idx < (size - 1))
                deststr [idx++] = srcstr [i];
            else
                return rep;
        }
    }
    deststr [idx] = '\0';
    return rep;
}
