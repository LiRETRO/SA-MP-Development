CMD:togemailcheck(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 1337) return 1;
	SendClientMessageEx(playerid, -1, emailcheck ? ("Email checks disabled"):("Email checks enabled"));
	emailcheck = !emailcheck;
	return 1;
}

InvalidEmailCheck(playerid, email[], task)
{
	if(isnull(email))
		return ShowPlayerDialogEx(playerid, EMAIL_VALIDATION, DIALOG_STYLE_INPUT, "E-mail Registration", "Please enter a valid e-mail address to associate with your account.", "Submit", "");
	szMiscArray[0] = 0;
	format(szMiscArray, sizeof(szMiscArray), "%s/email_check.php?t=%d&e=%s", SAMP_WEB, task, email);
	HTTP(playerid, HTTP_GET, szMiscArray, "", "OnInvalidEmailCheck");
	return 1;
}

forward OnInvalidEmailCheck(playerid, response_code, data[]);
public OnInvalidEmailCheck(playerid, response_code, data[])
{
	if(response_code == 200)
	{
		new result = strval(data);
		if(result == 0) // Invalid, Show dialog
			ShowPlayerDialogEx(playerid, EMAIL_VALIDATION, DIALOG_STYLE_INPUT, "E-mail Registration - {FF0000}Error", "Please enter a valid e-mail address to associate with your account.", "Submit", "");
		if(result == 1) // Valid from login check
			if(!GetPVarInt(playerid, "EmailConfirmed"))
				ShowPlayerDialogEx(playerid, DIALOG_NOTHING, DIALOG_STYLE_MSGBOX, "Pending Email Confirmation",
				"Our records show that you have not confirmed your email address.\n\
				Daily reminders will be sent to the email registered with your account until it is confirmed.\n\
				Please make an effort to confirm it as it will be used for important changes and notifications in regards to your account.", "Okay", "");
		if(result == 2) // Valid from dialog
		{
			szMiscArray[0] = 0;
			GetPVarString(playerid, "pEmail", szMiscArray, 128);
			strcpy(PlayerInfo[playerid][pEmail], g_mysql_ReturnEscaped(szMiscArray, MainPipeline), 128);
			format(szMiscArray, sizeof(szMiscArray), "UPDATE `accounts` SET `Email` = '%s', `EmailConfirmed` = 0 WHERE `id` = %d", PlayerInfo[playerid][pEmail], PlayerInfo[playerid][pId]);
			mysql_function_query(MainPipeline, szMiscArray, false, "OnQueryFinish", "i", SENDDATA_THREAD);
			format(szMiscArray, sizeof(szMiscArray), "A confirmation email will be sent to '%s' soon.\n\
			This email will need to be confirmed within 7 days or you will be prompted to enter a new one.\n\
			Please make an effort to confirm it as it will be used for important changes and notifications in regards to your account.", PlayerInfo[playerid][pEmail]);
			ShowPlayerDialogEx(playerid, DIALOG_NOTHING, DIALOG_STYLE_MSGBOX, "Email Confirmation", szMiscArray, "Okay", "");
			format(szMiscArray, sizeof(szMiscArray), "%s/mail.php?id=%d", CP_WEB, PlayerInfo[playerid][pId]);
			HTTP(playerid, HTTP_HEAD, szMiscArray, "", "");
		}
	}
	return 1;
}

#include <YSI\y_hooks>
hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == EMAIL_VALIDATION)
	{
		if(!response || isnull(inputtext))
			ShowPlayerDialogEx(playerid, EMAIL_VALIDATION, DIALOG_STYLE_INPUT, "E-mail Registration - {FF0000}Error", "Please enter a valid e-mail address to associate with your account.", "Submit", "");
		SetPVarString(playerid, "pEmail", inputtext);
		InvalidEmailCheck(playerid, inputtext, 2);
	}
	return 1;
}