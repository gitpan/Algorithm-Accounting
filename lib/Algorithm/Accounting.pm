package Algorithm::Accounting;
use strict;
use warnings;
use Spiffy '-Base';
use Perl6::Form;
our $VERSION = '0.02';

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
      if('ARRAY' eq ref($_->[$i])) {
	for my $v (@{$_->[$i]}) {$occ->{$v}++}
      } else {
        $occ->{$_->[$i]}++;
      }
    }
    $aocc->[$i] = $occ;
    $hocc->{$fields->[$i]} = $occ;
  }
  $self->_occurrence_array($aocc);
  $self->_occurrence_hash($hocc);
}

sub report {
  for(keys %{$self->_occurrence_hash}) {
    $self->_report_occurrence_percentage($_);
  }
}

# Do I really have to named it so ?
sub _report_occurrence_percentage {
  my $field = shift;
  my $occ  = $self->_occurrence_hash->{$field};
  my $rows = sub {my $r; for(@_) {$r+=$_} $r}->(values %$occ);
  print form
    "+===========================================+",
    "| Field: {<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<} |",
    $field,
    "| {>>>>>>>>>>>>>>>>>>>>>>>>} | {>>>>>>>>>>} |",
    'Value',                         'Percentage',
    "+===========================================+";

  for(sort {$occ->{$b} <=> $occ->{$a} } keys %$occ) {
    print form
      "| {>>>>>>>>>>>>>>>>>>>>>>>>} | {>>>>>>>>.}% |",
	$_,     (100 * $occ->{$_} / $rows) ;
  }
  print form "+===========================================+";
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
	[5, 'john ', [qw(/foo.txt /bar.txt], '2004-05-04' ],
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

C<Algorithm::Accounting> provide simple aggregation method to make log
accounting easier. It accepts data in rows, each rows can have many
fields, and each field is a scalar or a list(arrayref).

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

