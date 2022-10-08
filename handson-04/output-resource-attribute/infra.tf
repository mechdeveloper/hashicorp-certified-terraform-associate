resource "aws_eip" "infra-eip" {
}

output "output-infra-publicipv4" {
  value = aws_eip.infra-eip.public_ip
}

# Output value 
# ```
# ...
# aws_eip.infra-eip: Creating...
# aws_eip.infra-eip: Creation complete after 1s [id=eipalloc-0e98a3e254f2530db]

# Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

# Outputs:

# output-infra-publicipv4 = "44.241.221.30"
# ```