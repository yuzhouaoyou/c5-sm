/*  CS:GO Gloves SourceMod Plugin
 *
 *  Copyright (C) 2017 Kağan 'kgns' Üstüngel
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

public int GloveMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				int team = GetClientTeam(client);
				
				char gloveIdStr[255];
				menu.GetItem(selection, gloveIdStr, sizeof(gloveIdStr));

				char buffers[3][128];
				ExplodeString(gloveIdStr, ";", buffers, 3, sizeof(buffers[]));
				int groupId = StringToInt(buffers[0]);
				int gloveId = StringToInt(buffers[1]);

				g_iGroup[client][team] = groupId;
				g_iGloves[client][team] = gloveId;
				
				char updateFields[128];
				char teamName[4];
				if(team == CS_TEAM_CT)
				{
					teamName = "ct";
				}
				else
				{
					teamName = "t";
				}
				Format(updateFields, sizeof(updateFields), "%s_group = %d, %s_glove = %d", teamName, groupId, teamName, gloveId);
				UpdatePlayerData(client, updateFields);
				
				if(team == GetClientTeam(client))
				{
					int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
					if(activeWeapon != -1)
					{
						SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1);
					}
					GivePlayerGloves(client);
					if(activeWeapon != -1)
					{
						DataPack dpack;
						CreateDataTimer(0.1, ResetGlovesTimer, dpack);
						dpack.WriteCell(client);
						dpack.WriteCell(activeWeapon);
					}
				}
				
				DataPack pack;
				CreateDataTimer(0.5, GlovesMenuTimer, pack);
				pack.WriteCell(menu);
				pack.WriteCell(client);
				pack.WriteCell(GetMenuSelectionPosition());
			}
		}
		case MenuAction_DisplayItem:
		{
			if(IsClientInGame(client))
			{
				char info[32];
				char display[64];
				menu.GetItem(selection, info, sizeof(info));
				
				if (StrContains(info, "-1") > -1)
				{
					Format(display, sizeof(display), "%T", "RandomGloves", client);
					return RedrawMenuItem(display);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				menuGlovesGroup[g_iClientLanguage[client]].DisplayAt(client, g_iLastGlovesGroupPosition[client], MENU_TIME_FOREVER);
			}
		}
	}
	return 0;
}

public Action ResetGlovesTimer(Handle timer, DataPack pack)
{
	ResetPack(pack);
	int clientIndex = pack.ReadCell();
	int activeWeapon = pack.ReadCell();
	
	if(IsClientInGame(clientIndex) && IsValidEntity(activeWeapon))
	{
		SetEntPropEnt(clientIndex, Prop_Send, "m_hActiveWeapon", activeWeapon);
	}
}

public int GloveMainMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char info[20];
				menu.GetItem(selection, info, sizeof(info));
				int index = StringToInt(info);
				int team = GetClientTeam(client);
				if(index == 0 || index == -1)
				{
					char teamName[4];

					g_iGroup[client][team] = index;
					g_iGloves[client][team] = index;
					if(team == CS_TEAM_CT)
					{
						teamName = "ct";
					}
					else
					{
						teamName = "t";
					}
					char updateFields[128];
					Format(updateFields, sizeof(updateFields), "%s_group = %d, %s_glove = %d", teamName, index, teamName, index);
					UpdatePlayerData(client, updateFields);
					
					if(team == GetClientTeam(client))
					{
						int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
						if(activeWeapon != -1)
						{
							SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1);
						}
						if(index == 0)
						{
							int ent = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
							if(ent != -1)
							{
								AcceptEntityInput(ent, "KillHierarchy");
							}
							SetEntPropEnt(client, Prop_Send, "m_hMyWearables", -1);
						}
						GivePlayerGloves(client);
						if(activeWeapon != -1)
						{
							DataPack dpack;
							CreateDataTimer(0.1, ResetGlovesTimer, dpack);
							dpack.WriteCell(client);
							dpack.WriteCell(activeWeapon);
						}
					}
					
					DataPack pack;
					CreateDataTimer(0.5, GlovesMenuTimer, pack);
					pack.WriteCell(menu);
					pack.WriteCell(client);
					pack.WriteCell(GetMenuSelectionPosition());
				}
				else
				{
					g_iLastGlovesGroupPosition[client] = GetMenuSelectionPosition();
					
					menuGloves[g_iClientLanguage[client]][index].Display(client, MENU_TIME_FOREVER);
				}
			}
		}
		case MenuAction_DisplayItem:
		{
			if(IsClientInGame(client))
			{
				char info[32];
				char display[64];
				menu.GetItem(selection, info, sizeof(info));
				
				if (StrEqual(info, "0"))
				{
					Format(display, sizeof(display), "%T", "DefaultGloves", client);
					return RedrawMenuItem(display);
				}
				else if (StrEqual(info, "-1"))
				{
					Format(display, sizeof(display), "%T", "RandomGloves", client);
					return RedrawMenuItem(display);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				CreateMainMenu(client).Display(client, MENU_TIME_FOREVER);
			}
		}
	}
	return 0;
}

public Action GlovesMenuTimer(Handle timer, DataPack pack)
{
	ResetPack(pack);
	Menu menu = pack.ReadCell();
	int clientIndex = pack.ReadCell();
	int menuSelectionPosition = pack.ReadCell();
	
	if(IsClientInGame(clientIndex))
	{
		menu.DisplayAt(clientIndex, menuSelectionPosition, MENU_TIME_FOREVER);
	}
}

Menu CreateFloatMenu(int client)
{
	char buffer[60];
	Menu menu = new Menu(FloatMenuHandler);
	int team = GetClientTeam(client);

	float fValue = g_fFloatValue[client][team];
	fValue = fValue * 100.0;
	int wear = 100 - RoundFloat(fValue);
	
	menu.SetTitle("%T%d%%", "SetFloat", client, wear);
	
	Format(buffer, sizeof(buffer), "%T", "Increase", client, g_iFloatIncrementPercentage);
	menu.AddItem("increase", buffer, wear == 100 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	Format(buffer, sizeof(buffer), "%T", "Decrease", client, g_iFloatIncrementPercentage);
	menu.AddItem("decrease", buffer, wear == 0 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	menu.ExitBackButton = true;
	
	return menu;
}

public int FloatMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				int team = GetClientTeam(client);

				char buffer[30];
				menu.GetItem(selection, buffer, sizeof(buffer));
				if(StrEqual(buffer, "increase"))
				{
					g_fFloatValue[client][team] = g_fFloatValue[client][team] - g_fFloatIncrementSize;
					if(g_fFloatValue[client][team] < 0.0)
					{
						g_fFloatValue[client][team] = 0.0;
					}
					if(g_FloatTimer[client] != INVALID_HANDLE)
					{
						KillTimer(g_FloatTimer[client]);
						g_FloatTimer[client] = INVALID_HANDLE;
					}
					DataPack pack;
					g_FloatTimer[client] = CreateDataTimer(2.0, FloatTimer, pack);
					pack.WriteCell(client);
					pack.WriteCell(team);
					CreateFloatMenu(client).Display(client, MENU_TIME_FOREVER);
				}
				else if(StrEqual(buffer, "decrease"))
				{
					g_fFloatValue[client][team] = g_fFloatValue[client][team] + g_fFloatIncrementSize;
					if(g_fFloatValue[client][team] > 1.0)
					{
						g_fFloatValue[client][team] = 1.0;
					}
					if(g_FloatTimer[client] != INVALID_HANDLE)
					{
						KillTimer(g_FloatTimer[client]);
						g_FloatTimer[client] = INVALID_HANDLE;
					}
					DataPack pack;
					g_FloatTimer[client] = CreateDataTimer(1.0, FloatTimer, pack);
					pack.WriteCell(client);
					pack.WriteCell(team);
					CreateFloatMenu(client).Display(client, MENU_TIME_FOREVER);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				CreateMainMenu(client).Display(client, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action FloatTimer(Handle timer, DataPack pack)
{

	ResetPack(pack);
	int clientIndex = pack.ReadCell();
	int team = pack.ReadCell();
	
	if(IsClientInGame(clientIndex))
	{
		char updateFields[30];
		char teamName[2];
		if(team == CS_TEAM_T)
		{
			teamName = "t";
		}
		else if(team == CS_TEAM_CT)
		{
			teamName = "ct";
		}
		Format(updateFields, sizeof(updateFields), "%s_float = %.2f", teamName, g_fFloatValue[clientIndex][team]);
		UpdatePlayerData(clientIndex, updateFields);
		
		if(team == GetClientTeam(clientIndex))
			GivePlayerGloves(clientIndex);
		
		g_FloatTimer[clientIndex] = INVALID_HANDLE;
	}
}

public int MainMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			
			if(IsClientInGame(client))
			{
				char info[10];
				menu.GetItem(selection, info, sizeof(info));
				
				if(StrEqual(info, "float"))
				{
					CreateFloatMenu(client).Display(client, MENU_TIME_FOREVER);
				}
				else if (StrEqual(info, "glove"))
				{
					menuGlovesGroup[g_iClientLanguage[client]].Display(client, MENU_TIME_FOREVER);
				}
				else if (StrEqual(info, "seed"))
				{
					CreateSeedMenu(client).Display(client, MENU_TIME_FOREVER);
				}
				else if (StrEqual(info, "invoke"))
				{
						
					int team = GetClientTeam(client);
					int otherTeam = team == CS_TEAM_CT ? CS_TEAM_T : CS_TEAM_CT;

					g_iGroup[client][otherTeam] = g_iGroup[client][team];
					g_iGloves[client][otherTeam] = g_iGloves[client][team];
					g_fFloatValue[client][otherTeam] = g_fFloatValue[client][team];
					g_iSeed[client][otherTeam] = g_iSeed[client][team];
					

					char updateFields[128];
					char teamName[4];
					if(otherTeam == CS_TEAM_CT)
					{
						teamName = "ct";
					}
					else
					{
						teamName = "t";
					}
					Format(updateFields, sizeof(updateFields), "%s_group = %d, %s_glove = %d, %s_float = %.2f, %s_seed = %d", teamName, g_iGroup[client][otherTeam], teamName, g_iGloves[client][otherTeam], teamName, g_fFloatValue[client][otherTeam], teamName, g_iSeed[client][otherTeam]);
					UpdatePlayerData(client, updateFields);
					
					CreateTimer(0.5, MainMenuTimer, GetClientUserId(client));
				}
				else if (StrEqual(info, "lang"))
				{
					CreateLanguageMenu(client).Display(client, MENU_TIME_FOREVER);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				ClientCommand(client, "sm_diy");
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

Menu CreateMainMenu(int client)
{
	char buffer[60];
	Menu menu = new Menu(MainMenuHandler, MENU_ACTIONS_DEFAULT);
	
	int team = GetClientTeam(client);
	menu.SetTitle("%T", "GloveMenuTitle", client);

	Format(buffer, sizeof(buffer), "%T", "ChooseGlove", client);
	menu.AddItem("glove", buffer);

	if (g_iGroup[client][team] == -1 && g_iGloves[client][team] == -1)
	{
		Format(buffer, sizeof(buffer), "%T", "RandomBoth", client);
	}
	else if (g_iGroup[client][team] != -1 && g_iGloves[client][team] == -1)
	{
		Format(buffer, sizeof(buffer), "%T", "RandomSkin", client);
	}
	else
	{
		Format(buffer, sizeof(buffer), "%T", "RandomOff", client);
	}
	menu.AddItem("random", buffer, ITEMDRAW_DISABLED);
	
	if (g_iEnableFloat == 1)
	{
		float fValue = g_fFloatValue[client][team];
		fValue = fValue * 100.0;
		int wear = 100 - RoundFloat(fValue);
		AddMenuOptionIsEnable(menu, (CS_TEAM_T <= team <= CS_TEAM_CT && g_iGroup[client][team] != 0 && IsPlayerAlive(client)) && !IsCustomGlove(g_iGloves[client][team]), "float", "%T%d%%", "SetFloat", client, wear);
	}
	AddMenuOptionIsEnable(menu, g_iGroup[client][team] != 0 && !IsCustomGlove(g_iGloves[client][team]), "seed", "%T", "Seed", client);

	Format(buffer, sizeof(buffer), "%T", "Invoke", client);
	menu.AddItem("invoke", buffer);
	Format(buffer, sizeof(buffer), "%T", "Language", client);
	menu.AddItem("lang", buffer);

	if(LibraryExists("diy"))
	{
		menu.ExitBackButton = true;
	}
	
	return menu;
}

public Action MainMenuTimer(Handle timer, int userid)
{
	int clientIndex = GetClientOfUserId(userid);
	if(IsPlayer(clientIndex))
	{
		CreateMainMenu(clientIndex).Display(clientIndex, MENU_TIME_FOREVER);
	}
}

Menu CreateSeedMenu(int client)
{
	int team = GetClientTeam(client);
	Menu menu = new Menu(SeedMenuHandler);

	char buffer[128];

	if (g_iSeed[client][team] != -1)
	{
		Format(buffer, sizeof(buffer), "%T", "SeedTitle", client, g_iSeed[client][team]);
	}
	else if (g_iSeedRandom[client][team] > 0)
	{
		Format(buffer, sizeof(buffer), "%T", "SeedTitle", client, g_iSeedRandom[client][team]);
	}
	else
	{
		Format(buffer, sizeof(buffer), "%T", "SeedTitleNoSeed", client);
	}
	
	menu.SetTitle(buffer);

	Format(buffer, sizeof(buffer), "%T", "SeedRandom", client);
	menu.AddItem("rseed", buffer);

	Format(buffer, sizeof(buffer), "%T", "SeedManual", client);
	menu.AddItem("cseed", buffer);

	Format(buffer, sizeof(buffer), "%T", "SeedSave", client);
	menu.AddItem("sseed", buffer, g_iSeedRandom[client][team] == 0 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

	Format(buffer, sizeof(buffer), "%T", "ResetSeed", client);
	menu.AddItem("seedr", buffer, g_iSeed[client][team] == -1 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

	menu.ExitBackButton = true;
	
	return menu;
}

public int SeedMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				int team = GetClientTeam(client);
				
				char teamName[4];
				if(team == CS_TEAM_CT)
				{
					teamName = "ct";
				}
				else
				{
					teamName = "t";
				}

				char buffer[30];
				menu.GetItem(selection, buffer, sizeof(buffer));
				if(StrEqual(buffer, "rseed"))
				{
					g_iSeed[client][team] = -1;

					if(team == GetClientTeam(client))
					{
						int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
						if(activeWeapon != -1)
						{
							SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1);
						}
						GivePlayerGloves(client);
						if(activeWeapon != -1)
						{
							DataPack dpack;
							CreateDataTimer(0.1, ResetGlovesTimer, dpack);
							dpack.WriteCell(client);
							dpack.WriteCell(activeWeapon);
						}
					}

					CreateTimer(0.5, SeedMenuTimer, GetClientUserId(client));
				}
				else if (StrEqual(buffer, "cseed"))
				{
					g_bWaitingForSeed[client] = true;
					PrintToChat(client, " %s \x04%t", g_ChatPrefix, "SeedInstruction");
				}
				else if (StrEqual(buffer, "sseed"))
				{
					if(g_iSeedRandom[client][team] > 0) 
					{
						g_iSeed[client][team] = g_iSeedRandom[client][team];
					}
					g_iSeedRandom[client][team] = 0;

					if(team == GetClientTeam(client))
					{
						int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
						if(activeWeapon != -1)
						{
							SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1);
						}
						GivePlayerGloves(client);
						if(activeWeapon != -1)
						{
							DataPack dpack;
							CreateDataTimer(0.1, ResetGlovesTimer, dpack);
							dpack.WriteCell(client);
							dpack.WriteCell(activeWeapon);
						}
					}


					char updateFields[256];
					Format(updateFields, sizeof(updateFields), "%s_seed = %d", teamName, g_iSeed[client][team]);
					UpdatePlayerData(client, updateFields);
					CreateTimer(0.5, SeedMenuTimer, GetClientUserId(client));

					PrintToChat(client, " %s \x04%t", g_ChatPrefix, "SeedSaved");
				}
				else if (StrEqual(buffer, "seedr"))
				{
					g_iSeed[client][team] = -1;
					g_iSeedRandom[client][team] = 0;
					
					char updateFields[256];

					Format(updateFields, sizeof(updateFields), "%s_seed = -1", teamName);
					UpdatePlayerData(client, updateFields);
					CreateTimer(0.5, SeedMenuTimer, GetClientUserId(client));
					
					PrintToChat(client, " %s \x04%t", g_ChatPrefix, "SeedReset");
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				CreateMainMenu(client).Display(client, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action SeedMenuTimer(Handle timer, int userid)
{
	int clientIndex = GetClientOfUserId(userid);
	if(IsPlayer(clientIndex))
	{
		CreateSeedMenu(clientIndex).Display(clientIndex, MENU_TIME_FOREVER);
	}
}

Menu CreateLanguageMenu(int client)
{
	Menu menu = new Menu(LanguageMenuHandler);
	menu.SetTitle("%T", "ChooseLanguage", client);
	
	char buffer[4];
	
	for (int i = 0; i < sizeof(g_Language); i++)
	{
		if(strlen(g_Language[i]) == 0)
			break;
		IntToString(i, buffer, sizeof(buffer));
		menu.AddItem(buffer, g_Language[i]);
	}
	
	menu.ExitBackButton = true;
	
	return menu;
}

public int LanguageMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char langIndexStr[4];
				menu.GetItem(selection, langIndexStr, sizeof(langIndexStr));
				int langIndex = StringToInt(langIndexStr);
				
				g_iClientLanguage[client] = langIndex;
				
				CreateMainMenu(client).Display(client, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_Cancel:
		{
			if(IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				CreateMainMenu(client).Display(client, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}
