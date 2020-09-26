/* Terminal colors (16 first used in escape sequence) */
static const char *colorname[] = {
"#3f3f3f",
"#cc9393",
"#7f9f7f",
"#d0bf8f",
"#6ca0a3",
"#dc8cc3",
"#93e0e3",
"#dcdccc",
"#000000",
"#dca3a3",
"#bfebbf",
"#f0dfaf",
"#8cd0d3",
"#dc8cc3",
"#93e0e3",
"#ffffff",

	[255] = 0,

	/* more colors can be added after 255 to use with DefaultXX */
"#3f3f3f",
"#dcdccc",
"#aaaaaa",

};


/*
 * Default colors (colorname index)
 * foreground, background, cursor, reverse cursor
 */
static unsigned int defaultfg = 257;
static unsigned int defaultbg = 256;
static unsigned int defaultcs = 258;
static unsigned int defaultrcs = 256;
