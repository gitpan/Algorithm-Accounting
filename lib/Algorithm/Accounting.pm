package Algorithm::Accounting;
use strict;
use warnings;
use Spiffy '-Base';
our $VERSION = '0.01';

field fields            => [];
field _occurrence_array => [];
field _occurrence_hash  => {};

sub reset {
  $self->fields([]);
  $self->_occurrence_array([]);
  $self->_occurrence_hash({});
}

sub result {
  my $field = shift;
  if($field && grep /^$field$/,@{$self->fields}) {
    return $self->_occurrence_hash->{$field};  
  }
  return $self->_occurrence_array;
}

sub append_data {
  my $data = shift;
  my $aocc = $self->_occurrence_array;
  my $hocc = $self->_occurrence_hash;
  my $fields = $self->fields;
  for my $i (0..scalar(@$fields)-1) {
    my $occ = $aocc->[$i] || {};
    for(@$data) {
      last unless exists $_->[$i];
      $occ->{$_->[$i]}++;
    }
    $aocc->[$i] = $occ;
    $hocc->{$fields->[$i]} = $occ;
  }
  $self->_occurrence_array($aocc);
  $self->_occurrence_hash($hocc);
}

sub report {
  for(@{$self->_occurrence_array}) {
    print "-" x 72 . "\n";
    print $self->_report_occurrence_percentage($_);
    print "-" x 72 . "\n";
  }
}

# Do I really have to named it so ?
sub _report_occurrence_percentage {
  my $occ  = shift;
  my $rows = sub {my $r; for(@_) {$r+=$_} $r}->(values %$occ);
  for(sort {$occ->{$b} <=> $occ->{$a} } keys %$occ) {
    printf("%16s : %5.2f%%\n",$_, 100* $occ->{$_} / $rows );
  }
}

1;

__END__

=head1 NAME

  Algorithm::Accounting - Generate accounting statistic for general logs

=head1 SYNOPSIS

  my $fields = [qw/id author file date/];
  my $data = [
	[1, 'alice', '/foo.txt', '2004-05-01' ],
	[2, 'bob',   '/foo.txt', '2004-05-03' ],
	[3, 'alice', '/foo.txt', '2004-05-04' ],
	[4, 'john ', '/foo.txt', '2004-05-04' ],
  ];

  my $acc = Algorithm::Accounting->new();

  # give the object information
  $acc->fields($fields):
  $acc->append_data($data);

  # Generate report to STDOUT
  $acc->report;

  # Get result
  my $result = $acc->result;

  # Get result of a specific field.
  my $author_accounting = $acc->result('author');

  # Reset current result so we can restart
  $acc->reset;

=head1 DESCRIPTION

C<Algorithm::Accounting> provide simple aggregation method to make
log accounting easier. It accpes data in rows, each rows can have
many fields, and each field is a scalar (In the future, it's planned
to let the value in fields could be a list).

The basic usage is you walk through all your logs, and use append_data()
to insert each rows, (you'll have to split the line into fields),
and then call result() to retrieve the result, or report() to
immediatly see simple result.

So far the accounting is only about one field, and it's planned to
implement multi-field accounting, so one can easily see the co-relation
of two fields.

Notice you'll have to give a list fileds first, the append_data()
depends on the number of fields to work properly.

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

