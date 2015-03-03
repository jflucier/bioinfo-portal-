use MyPackage;
my $object = MyPackage->new(
    prop1 => 3012,
    prop3 => 42,
    prop5 => 'fine',
);
print("prop1: ", $object->get_prop1, "\n");
print("prop2: ", $object->get_prop2, "\n");
print("prop3: ", $object->get_prop3, "\n");
print("prop4: ", $object->get_prop4("xxxxxxxxxxxxxxxx"), "\n");
print("prop5: ", $object->get_prop5, "\n");
print("Changing the value of prop5 to 'bad'\n");
$object->prop5('bad');
print("prop5: ", $object->get_prop5, "\n");
