package Algorithm::Accounting;
use strict;
use warnings;
use Spiffy '-Base';
use Perl6::Form;
use Array::Compare;
use List::Permutor::LOL;
use FreezeThaw qw(freeze thaw);
our $VERSION = '0.03';

field fields            => [];
field _occurrence_array => [];
field _occurrence_hash  => {};

# arrayref of arrayref
field field_groups      => [];

# array of hashref, but the key of hashref is
# in serialized(freezed) form.
field _group_occurrence => [];

sub reset {
  $self->fields([]);
  $self->field_groups([]);
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

sub group_result {
  my ($group,@fv) = @_;
  my $occ   = $self->_group_occurrence;
  return unless($group =~ /\d+/ && defined($occ->[$group]));
  # Exact match;
  my $cmp = Array::Compare->new;
  if(@fv == @{$self->field_groups->[$group]}) {
    for(keys %{$occ->[$group]}) {
      my @fv_ = thaw($_);
      next unless($cmp->compare(\@fv, \@fv_));
      return $occ->[$group]{$_};
    }
  }
  # Slurp whole thing, convert to multi-level hash.
  my $rv = {};
  for(keys %{$occ->[$group]}) {
    # would this be dangerous ?
    eval "\$rv->".join('',map {"{'$_'}"} thaw($_))."= $occ->[$group]{$_}";
  }
  return $rv;
}

sub append_data {
  my $data = shift;
  $self->_update_single_field($data);
  $self->_update_group_field($data);
}

sub report {
  for(keys %{$self->_occurrence_hash}) {
    $self->_report_occurrence_percentage($_);
  }
  for(0..@{$self->field_groups}-1) {
    $self->_report_field_group_occurrence_percentage($_);
  }
}

sub _update_group_field {
  my $data = shift;
  my $groups = $self->field_groups || return;
  my $gocc = $self->_group_occurrence;
  for my $i (0..@$groups-1) {
    my @index = $self->_position_of($self->fields,$groups->[$i]);
    for my $row (@$data) {
      my $permutor = List::Permutor::LOL->new([@$row[@index]]);
      while(my $permutation = $permutor->next) {
	my @_row = map {(ref($_) ? $_->[0] : $_) || ''} @$permutation;
	$gocc->[$i]->{freeze(@_row)}++;
      }
    }
  }
  $self->_group_occurrence($gocc);
}

sub _update_single_field {
  my $data = shift;
  my $aocc = $self->_occurrence_array;
  my $hocc = $self->_occurrence_hash;
  my $fields = $self->fields;
  for my $i (0..@$fields-1) {
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

# Do I really have to named it so ?
sub _report_occurrence_percentage {
  my $field = shift;
  my $occ  = $self->_occurrence_hash->{$field};
  my $rows = sub {my $r; for(@_) {$r+=$_} $r}->(values %$occ);
  print form
    "+===========================================+",
    "| {>>>>>>>>>>>>>>>>>>>>>>>>} | {>>>>>>>>>>} |",
       $field,                      'Percentage',
    "+===========================================+";

  for(sort {$occ->{$b} <=> $occ->{$a} } keys %$occ) {
    print form
      "| {>>>>>>>>>>>>>>>>>>>>>>>>} | {>>>>>>>>.}% |",
	$_,     (100 * $occ->{$_} / $rows) ;
  }
  print form "+===========================================+";
}

sub _report_field_group_occurrence_percentage {
  my $i = shift; # Only the i-th field group
  my @field = @{$self->field_groups->[$i]};
  my $occ  = $self->_group_occurrence->[$i];
  my $rows = sub {my $r; for(@_) {$r+=$_} $r}->(values %$occ);
  local $, = ',';

  my $form_format = '|' . join('|',map {'{<<<<<<<<<<<<}'} @field) . '|{>>>>>>>>>>}|';
  my $sep = '+' . '=' x (14*(1+@field)) . '+';
  print form $sep , $form_format, @field, "Percentage",$sep ;
  $form_format =~ s/>>}\|$/.}%|/;
  for(sort { (thaw($a))[0] cmp (thaw($b))[0] } keys %$occ) {
    my @fv = thaw($_);
    print form
      $form_format ,
      @fv, (100 * $occ->{$_} / $rows);
  }
  print form $sep;
}

# Find the position of wanted values in an array
sub _position_of {
  my ($arr,$wanted) = @_;
  my @index;
  for my $w (@$wanted) {
    for my $i (0..@$arr-1) {
      push @index,$i if($arr->[$i] eq $w);
    }
  }
  return @index;
}

1;

__END__

=head1 NAME

  Algorithm::Accounting - Generate accounting statistic for general logs

=head1 SYNOPSIS

  my $fields = [qw/id author file date/];
  my $groups = [[qw(author file)], [qw(author date)]];
  my $data = [
	[1, 'alice', '/foo.txt', '2004-05-01' ],
	[2, 'bob',   '/foo.txt', '2004-05-03' ],
	[3, 'alice', '/foo.txt', '2004-05-04' ],
	[4, 'john ', '/foo.txt', '2004-05-04' ],
	[5, 'john ', [qw(/foo.txt /bar.txt], '2004-05-04' ],
  ];


  # give the object information
  my $acc = Algorithm::Accounting->new(fields => $fields,
                                       field_groups => $groups );

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

You may specify a filed_groups parameter (arrayref of arrayref),
and C<Algorithm::Accounting> will account these fields in groups.

Notice you'll have to give a list fileds first, the append_data()
depends on the number of fields to work properly.

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

