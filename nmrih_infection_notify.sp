#pragma semicolon 1
#include <sdkhooks> // 确保你已经安装了 SourceMod 和 SDKHooks

#define PLUGIN_VERSION "0.1"

// 存储玩家的感染状态，true 表示已感染，false 表示未感染
new bool:g_bIsInfected[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "[NMRiH] Infection Notification",
	author = "PLTAT",
	description = "Infection Notification for NMRiH",
	version = PLUGIN_VERSION,
	url = "http://pltat.github.io"
};

public OnPluginStart()
{
	decl String:game[16];
	GetGameFolderName(game, sizeof(game));
	if (strcmp(game, "nmrih", false) != 0)
	{
		SetFailState("插件仅支持NMRiH游戏!");
	}

	CreateConVar("sm_nmrih_infection_version", PLUGIN_VERSION, "[NMRiH] Infection Notification version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	LoadTranslations("nmrih_infection.phrases"); // 加载独立的语言文件

	// 注册事件钩子
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);

	// 启动定时器，定期检查玩家状态
	CreateTimer(0.2, Timer_CheckPlayerStatus, _, TIMER_REPEAT);
}

public OnPluginEnd()
{
    // 插件卸载时，清空所有玩家的感染状态，防止下次加载时状态异常
    for (new i = 1; i <= MAXPLAYERS; i++)
    {
        g_bIsInfected[i] = false;
    }
}

public Action:Timer_CheckPlayerStatus(Handle:timer)
{
	for (new Client = 1; Client <= MaxClients; Client++) // 使用 MaxClients 来代替硬编码的 8
	{
		if (IsValidClient(Client)) // 检查客户端是否有效且在游戏中
		{
			// 检查玩家是否感染
			if (IsClientInfected(Client))
			{
				// 如果玩家之前未感染，现在感染了，则发送通知
				if (!g_bIsInfected[Client])
				{
					g_bIsInfected[Client] = true;
					PrintToChatAll("\x01%N \x04%t", Client, "Notifi_Infection");
				}
			}
			else // 玩家未感染
			{
				g_bIsInfected[Client] = false; // 确保状态为未感染
			}
		}
	}
	return Plugin_Continue;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(Client))
	{
		// 玩家重生时，重置感染状态
		g_bIsInfected[Client] = false;
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(Client))
	{
		// 玩家死亡时，重置感染状态
		g_bIsInfected[Client] = false;
	}
}

// 辅助函数：判断客户端是否有效并处于游戏中且存活
stock bool:IsValidClient(Client)
{
	return (Client > 0 && Client <= MaxClients && IsClientConnected(Client) && IsClientInGame(Client) && IsPlayerAlive(Client));
}

// 辅助函数：判断玩家是否感染
stock bool:IsClientInfected(Client)
{
	// NMRiH 中感染的判断通常基于 m_flInfectionTime 和 m_flInfectionDeathTime 属性
	// 只有当两者都大于 0 时才认为玩家处于感染状态
	return (GetEntPropFloat(Client, Prop_Send, "m_flInfectionTime") > 0.0 && GetEntPropFloat(Client, Prop_Send, "m_flInfectionDeathTime") > 0.0);
}

/*
在 addons/sourcemod/translations 目录下创建 nmrih_infection.phrases 文件，内容如下：

"Phrases"
{
	"Notifi_Infection"
	{
		"en"	"has been infected!"
		"zh"	"被感染了!"
	}
}
*/
