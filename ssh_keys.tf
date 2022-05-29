# SSH Keys
resource "aws_key_pair" "laptop_k" {
  key_name   = "laptop_k"
  public_key = file(var.ssh_pub_path)

  tags = {
    Name     = "laptop_k"
    Usuario  = "Frank J. <ago>"
    Episodio = "Informe Nube "
  }
}
