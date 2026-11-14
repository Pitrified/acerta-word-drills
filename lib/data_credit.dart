import 'package:flutter/foundation.dart';

/// The data credit of `DATA_LICENSE.md`, as one paragraph.
const dataCredit =
    'Lexical data from lang-tools by Pietro Maria Nobili, licensed under CC BY 4.0 (https://github.com/Pitrified/lang-tools/blob/main/DATA_LICENSE.md). Built on Princeton WordNet 3.0, OpenWordnet-PT, the Multilingual Central Repository, MultiWordNet, the Collaborative Interlingual Index and wordfreq.';

/// The WordNet 3.0 license notice of `DATA_LICENSE.md`, word for word.
const wordNetLicense = '''WordNet Release 3.0

This software and database is being provided to you, the LICENSEE, by
Princeton University under the following license.  By obtaining, using
and/or copying this software and database, you agree that you have
read, understood, and will comply with these terms and conditions.:

Permission to use, copy, modify and distribute this software and
database and its documentation for any purpose and without fee or
royalty is hereby granted, provided that you agree to comply with
the following copyright notice and statements, including the disclaimer,
and that the same appear on ALL copies of the software, database and
documentation, including modifications that you make for internal
use or for distribution.

WordNet 3.0 Copyright 2006 by Princeton University.  All rights reserved.

THIS SOFTWARE AND DATABASE IS PROVIDED "AS IS" AND PRINCETON
UNIVERSITY MAKES NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR
IMPLIED.  BY WAY OF EXAMPLE, BUT NOT LIMITATION, PRINCETON
UNIVERSITY MAKES NO REPRESENTATIONS OR WARRANTIES OF MERCHANT-
ABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE OR THAT THE USE
OF THE LICENSED SOFTWARE, DATABASE OR DOCUMENTATION WILL NOT
INFRINGE ANY THIRD PARTY PATENTS, COPYRIGHTS, TRADEMARKS OR
OTHER RIGHTS.

The name of Princeton University or Princeton may not be used in
advertising or publicity pertaining to distribution of the software
and/or database.  Title to copyright in this software, database and
any associated documentation shall at all times remain with
Princeton University and LICENSEE agrees to preserve same.''';

/// Adds the WordNet notice and the data credit to the licenses page.
void registerDataLicenses() {
  LicenseRegistry.addLicense(
    () => Stream.fromIterable(const [
      LicenseEntryWithLineBreaks(['WordNet 3.0'], wordNetLicense),
      LicenseEntryWithLineBreaks(['lang-tools lexical data'], dataCredit),
    ]),
  );
}
