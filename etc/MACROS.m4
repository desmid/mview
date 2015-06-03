m4_divert(-1)
m4_changecom(/*,*/)

/*
 * Macro definitions for standard web page stuff and other constants that
 * may be propagated throughout these web pages. Be careful when inventing
 * macro names so that they don't look like something you would normally
 * see in your text to prevent unwanted substitutions! Absolutely anything
 * you want to define can be specified here, not just html things.
 *
 * Depends on the gnu m4 implementation with the -P flag to force all
 * builtin macros to begin with the 'm4_' prefix.
 *
 * In a document, c-style and hash comments are passed through, while
 * c-style comments are skipped in this macro file.
 *
 * If you need a literal comma inside an argument to a macro, you
 * can quote it thus `,' or you can use the HTML code &#44;
 *
 * If you need a begin quote you must use the HTML code &#96;
 *
 * http://www-phys.rrz.uni-hamburg.de/Software/HTMLdocs/NewHTML/iso_table.html
 * has a list of ISO-Latin-1 characters and HTML definitions.
 *
 *
 * Example:
 *
 *    m4_include(path to this macro definition file)
 *    
 *    _HTML_START(An imaginary page)
 *    
 *    Welcome to the _GROUPNAME pages at _HREF_EBI.
 *    
 *    <H3>Group interests</H3>
 *    <H3>Group members</H3>
 *    <H3>Projects</H3>
 *    <H3>Services mirrored from _HREF_EMBL</H3>
 *    
 *    You can use raw HTML in here, and/or use the macros.
 *
 *    <UL>
 *    <LI>This is how to do an _href(anchor.html, anchor) relative to here.
 *    <LI>The 'GeneQuiz' _HREF_GENEQUIZ server.
 *    </UL>
 *    
 *    _HTML_END
 *    
 *
 * Created 27-2-97 Nige
 * Changed 3-3-97  Nige, added m4_ prefix, divert, introductory text.
 * Changed 5-3-97  Nige, more URLs, HREFs, _WARNING, _GROUPNAME, _COLOR_*,
 *                 _HTML_START and _HTML_START_TOP macros.
 */ 

/* Me, Myself, I */
m4_define(_NIGENAME, Nigel P. Brown)
/* m4_define(_NIGEMAIL, npb@users.sourceforge.net) */
m4_define(_NIGEMAIL, biomview@gmail.com)
/* m4_define(_NIGEURL,  _URL_MATHBIO/~nbrown) */

/* the group identity */
m4_define(_GROUPNAME,          MView Project)

/* some handy gifs */
m4_define(_GIF_NEW,     <IMG SRC="_HTML_ROOT/gifs/new.gif" ALT="[new]">)
m4_define(_GIF_UPDATED, <IMG SRC="_HTML_ROOT/gifs/updated.gif" ALT="[update]">)
m4_define(_GIF_GREENBALL,<IMG SRC="_HTML_ROOT/gifs/greenball.gif" ALT="[o]">)

/* standard URLs @ SOURCEFORGE */
m4_define(_URL_SOURCEFORGE,    http://sourceforge.net)
m4_define(_URL_PROJECT,        http://bio-mview.sourceforge.net)

/* standard SOURCEFORGE stuff */
m4_define(_BUTTON_SOURCEFORGE, <a href="http://sourceforge.net"><img src="http://sflogo.sourceforge.net/sflogo.php?group_id=153760&amp;type=1" width="88" height="31" border="0" alt="SourceForge.net Logo" /></a>)
m4_define(_BUTTON_DONATION,    <a href="http://sourceforge.net/donate/index.php?group_id=153760"><img src="http://images.sourceforge.net/images/project-support.jpg" width="88" height="31" border="0" alt="Support This Project" /> </a>)

/* standard buttons */
m4_define(_BUTTON_PROJECT,     _href(_HTML_ROOT/index.html, <font size=+2>[Home]</font>))
m4_define(_BUTTON_FAQ,         _href(_HTML_ROOT/FAQ.html,   <font size=+2>[FAQ]</font>))

/* PROJECT group logo */
/* m4_define(_MATHBIO_LOGO,     _head1(_image(CENTER,_HTML_ROOT/images/mathbio_logo.gif,[MathBio logo],125,125) <FONT COLOR="#008800">NIMR _GROUPNAME</FONT>)) */

/* page colour scheme */
m4_define(_COLOR_BODY,       BGCOLOR="#AADDEE")
m4_define(_COLOR_TEXT,          TEXT="#000000")
m4_define(_COLOR_LINK)
m4_define(_COLOR_VLINK)
m4_define(_COLOR_ALINK)

/* standard information */
m4_define(_WEBMASTER,        _NIGENAME)
m4_define(_WEBMASTERMAIL,    _NIGEMAIL)
m4_define(_WEBMASTERSIG,     _small(Maintained by _href(MAILTO:_WEBMASTERMAIL, _WEBMASTER).))
m4_define(_UPDATE,           _small(Last update m4_esyscmd(/bin/date "+%b %e %Y")))

m4_define(_RULER,            
`<HR>
<table width="100%" cellspacing=0 cellpadding=2><tr>
 <td align="center">_BUTTON_PROJECT</td>   <td>&nbsp;</td>  <td align="center">_BUTTON_FAQ</td>
 <td width="70%">&nbsp;</td>
 <td align="center">_BUTTON_DONATION</td>  <td>&nbsp;</td>  <td align="center">_BUTTON_SOURCEFORGE</td>
</tr></table>
<HR>')

/* not needed for sourceforge */
/* m4_define(_DISCLAIMER, _href(_HTML_ROOT/etc/disclaimer.html, <SMALL>Disclaimer</SMALL>)) */
m4_define(_DISCLAIMER,)

/* SGML DTD for HTML 3.2 */
m4_define(_DOCTYPE, `<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2//EN">')

m4_define(_CSS,
`<STYLE type="text/css"
<!--
H1 {color:blue}
H2 {color:blue}
H3 {color:blue}
H4 {color:blue}
-->
</STYLE>')

/* document header - top level with logo */
m4_define(_HTML_START_TOP,       
`_DOCTYPE
<HTML>_head(_title(_GROUPNAME - $*))
_body
_PAGE_TOP')

/* document header - ordinary page */
m4_define(_HTML_START,       
`_DOCTYPE
<HTML>_head(_title(_GROUPNAME - $*))
_body
_PAGE_TOP
_head1($*)')

/* document header - very ordinary page */
m4_define(_HTML_START_NOGROUP,       
`_DOCTYPE
<HTML>_head(_title($*))
_body
_PAGE_TOP
_head1($*)')

/* document trailer */
m4_define(_HTML_END,         
`<P>
_RULER
_address(_WEBMASTERSIG _UPDATE. _DISCLAIMER)
</BODY></HTML>')

/* items in a FAQ list: name, text) */
m4_define(_FAQ_KEY,      `<A HREF="#$1">$2</A>')
m4_define(_FAQ_BEG,      `<H4><A NAME=$1>_BUTTON_TOP</A> $2</H4><BLOCKQUOTE>')
m4_define(_FAQ_END,      `</BLOCKQUOTE>')
m4_define(_BUTTON_TOP,   _href(_URL_PAGE_TOP, [top])))
m4_define(_PAGE_TOP,     <A NAME="TOP">)
m4_define(_URL_PAGE_TOP, #TOP)

/* items in a section list: name, text) */
m4_define(_SEC_BEG,      `<H4>$*</H4><BLOCKQUOTE>')
m4_define(_SEC_END,      `</BLOCKQUOTE>')


m4_define(_WARNING,    `<P>This page is under construction.')


/* html formatting commands */
m4_define(_head,       `<HEAD>$*</HEAD>')
m4_define(_title,      `<TITLE>m4_patsubst($*, </?[^>]+>)</TITLE>')
m4_define(_body,       `<BODY _COLOR_BODY _COLOR_TEXT _COLOR_LINK _COLOR_VLINK _COLOR_ALINK>')
   		       
m4_define(_head1,      `<H1>$*</H1>')
m4_define(_head2,      `<H2>$*</H2>')
m4_define(_head3,      `<H3>$*</H3>')
m4_define(_head4,      `<H4>$*</H4>')
m4_define(_head5,      `<H5>$*</H5>')
m4_define(_head6,      `<H6>$*</H6>')
m4_define(_para,       `<P>$*')

m4_define(_strong,     `<STRONG>$*</STRONG>')
m4_define(_small,      `<SMALL>$*</SMALL>')
m4_define(_code,       `<CODE>$*</CODE>')
m4_define(_italic,     `<I>$*</I>')
m4_define(_fontcolor,  `<FONT COLOR="$1">$2</FONT>')
  
m4_define(_href,       `<A HREF="$1">$2</A>')
m4_define(_name,       `<A NAME="$1">$2</A>')
m4_define(_image,      `<IMG ALIGN=$1 SRC="$2" ALT="$3" WIDTH=$4 HEIGHT=$5>')
m4_define(_imageext,   `_href("$*", link anchor)')
m4_define(_soundext,   `_href("$*", link anchor)')
m4_define(_movieext,   `_href("$*", link anchor)')

m4_define(_list, `m4_dnl
<UL>$*</UL>')

m4_define(_enum, `m4_dnl
<OL>$*</OL>')

m4_define(_item, `<LI>$*')

m4_define(_dlist, `m4_dnl
<DL>_desc($*)</DL>')

m4_define(_desc, `m4_dnl
<DT>$*<DD>$2')

m4_define(_preformat, `m4_dnl
<PRE>$*</PRE>')

m4_define(_quote, `m4_dnl
<BLOCKQUOTE>$*</BLOCKQUOTE>')

m4_define(_address, `m4_dnl
<ADDRESS>$*</ADDRESS>')

m4_define(_menu, `m4_dnl
<MENU>$*</MENU>')

m4_divert
