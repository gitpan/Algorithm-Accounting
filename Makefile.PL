use inc::Module::Install;

name            ('Algorithm-Accounting');
abstract        ('Generate accounting statistic for general logs');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Algorithm/Accounting.pm');
requires        ('Spiffy');
build_requires  ('Test::More');

&WriteAll;

