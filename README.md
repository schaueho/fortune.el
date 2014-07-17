## fortune.el

Copyright (C) 1999 Free Software Foundation, Inc.

Author: Holger Schauer <Holger.Schauer@gmx.de>
Keywords: games utils mail

This file is part of Emacs.

This utility allows you to automatically cut regions to a fortune
file.  In case that the region stems from an article buffer (mail or
news), it will try to automatically determine the author of the
fortune.  It will also allow you to compile your fortune-database
as well as providing a function to extract a fortune for use as your
signature.
Of course, it can simply display a fortune, too.
Use prefix arguments to specify different fortune databases.

## Installation:

Please check the customize settings - you will at least have to modify the
values of `fortune-dir` and `fortune-file`. I then use this in my .gnus:

	(message "Making new signature: %s"
		(fortune-to-signature "~/fortunes/"))

This automagically creates a new signature when starting up Gnus.
Note that the call to `fortune-to-signature` specifies a directory in which
several fortune-files and their databases are stored.

If you like to get a new signature for every message, you can also hook
it into message-mode:

	(add-hook 'message-setup-hook
          '(lambda ()
             (fortune-to-signature)))
			 
This time no fortune-file is specified, so fortune-to-signature would use
the default-file as specified by fortune-file.

I have also this in my .gnus:
	(add-hook 'gnus-article-mode-hook
	  '(lambda ()
	     (define-key gnus-article-mode-map "i" 'fortune-from-region)))
		 
which allows marking a region and then pressing "i" so that the marked 
region will be automatically added to my favourite fortune-file.

## Licence
GNU Emacs is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

GNU Emacs is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU Emacs; see the file COPYING.  If not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.
