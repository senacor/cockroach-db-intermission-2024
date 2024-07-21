module "first_region"{
  source = "../modules/cockroachDB"

  providers = {
    aws = aws.eu_central
  }
  number_of_available_zones = 2
  ec2_instance_type = "m6i.2xlarge"
  ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCuL0txPW8uhm0x+B+0AXnIWYPg+zNv0O4zEWFEHYWOyPEoTswyGBH66L6ieyQb6IXavQH3o5bcTPTW27TypeBg+BBO0TW6QsY3MOIsIHMSntmj/PP0elNqE0e5ATUoOhGAClViL5BvVJCKk1EaEbgnxdvTpBfYtSWJq/YJv3kneOGq08acoe6QupVFXZceBcz3bKcJ0Q9DCfvcol69l+KmO+FfPR3pw4zGDdgag7N1VmR076k2o4XTWFjT8BE3INE3u1soxYe7cf2bX4O9U418t5VNRrk1HDbnayPVlnFrx/H/3MnCaPu8UCttuKzbnQj3iFdR/0IQAyQm/w6cTNL3Ip7W/h4kb055hVgSzk3HwRS3b2SfGms1SWWVGJ7a9e6SdKsWpfF3YUyr+so5PwxXaN1cTeJRde7kiSluAdDiRt+t0n/B2kyyDdkUu17eCPhc6veTwV//H26RiHZkP/7Fy4IOLBYyhLVAbsEr+Jy02PGLm8iTfcQFaW3bPMW/P+xa1WivSAIGvqLXo2clUFS3U3VP98aJn7W9WNpQBq0tIju/wWa4T55W9O7YehbUEktFklcnGRj5psMUH2RL2BfU196PzFgfaAqZwGRjnoFUPji32JLYGTW/lFFBj/0KCV1FYPePwGdl3BuZNj5JEvwzIP6mceao46CYq+72kcd+uQ== dstruck@M032213600D.local"
}

module "second_region"{
  source = "../modules/cockroachDB"

  providers = {
     aws = aws.us_east_1
   }
  number_of_available_zones = 1
  ec2_instance_type = "m6i.2xlarge"
  ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCuL0txPW8uhm0x+B+0AXnIWYPg+zNv0O4zEWFEHYWOyPEoTswyGBH66L6ieyQb6IXavQH3o5bcTPTW27TypeBg+BBO0TW6QsY3MOIsIHMSntmj/PP0elNqE0e5ATUoOhGAClViL5BvVJCKk1EaEbgnxdvTpBfYtSWJq/YJv3kneOGq08acoe6QupVFXZceBcz3bKcJ0Q9DCfvcol69l+KmO+FfPR3pw4zGDdgag7N1VmR076k2o4XTWFjT8BE3INE3u1soxYe7cf2bX4O9U418t5VNRrk1HDbnayPVlnFrx/H/3MnCaPu8UCttuKzbnQj3iFdR/0IQAyQm/w6cTNL3Ip7W/h4kb055hVgSzk3HwRS3b2SfGms1SWWVGJ7a9e6SdKsWpfF3YUyr+so5PwxXaN1cTeJRde7kiSluAdDiRt+t0n/B2kyyDdkUu17eCPhc6veTwV//H26RiHZkP/7Fy4IOLBYyhLVAbsEr+Jy02PGLm8iTfcQFaW3bPMW/P+xa1WivSAIGvqLXo2clUFS3U3VP98aJn7W9WNpQBq0tIju/wWa4T55W9O7YehbUEktFklcnGRj5psMUH2RL2BfU196PzFgfaAqZwGRjnoFUPji32JLYGTW/lFFBj/0KCV1FYPePwGdl3BuZNj5JEvwzIP6mceao46CYq+72kcd+uQ== dstruck@M032213600D.local"
}