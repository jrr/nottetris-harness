-- Boot through the logo and title to the single player menu.
return {
	{state="logo", timeout=5}, {wait=0.5}, {shot="01_logo"},
	{press="return"}, {state="title"}, {wait=0.5}, {shot="02_title"},
	{press="return"}, {state="menu"}, {wait=0.5}, {shot="03_menu"},
	{dump="state"},
	{quit=true},
}
