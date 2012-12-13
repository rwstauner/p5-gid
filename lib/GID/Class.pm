package GID::Class;
# ABSTRACT: Making your classes in GID

use Package::Stash;
use Import::Into;
use Scalar::Util qw( blessed );

use GID ();
use Moo ();
use MooX ();

sub import {
	shift;
	my $target = scalar caller;

	GID->import::into($target,@_);

	my $stash = Package::Stash->new($target);
	my @gid_methods = $stash->list_all_symbols('CODE');

	MooX->import::into($target,qw(
		ClassStash
		HasEnv
		Options
	));

	$target->can('extends')->('GID::Object');

	$target->class_stash->around_method('has',sub {
		my $has = shift;
		my $attribute_arg = shift;
		my @attribute_args = @_;
		my @attributes = ref $attribute_arg eq 'ARRAY' ? @{$attribute_arg} : ($attribute_arg);
		for (@attributes) {
			my $attribute = $_;
			if (grep { $attribute eq $_ } @gid_methods) {
				my $gid_method = $target->class_stash->get_method($attribute);
				$target->class_stash->remove_method($attribute);
				$has->($attribute,@attribute_args);
				$target->class_stash->around_method($attribute,sub {
					my $attribute_method = shift;
					my @args = @_;
					if (blessed $args[0]) {
						return $attribute_method->(@args);
					} else {
						return $gid_method->(@args);
					}
				});
			} else {
				$has->($attribute,@attribute_args);
			}
		}
	});

}

1;