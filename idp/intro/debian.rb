
task "Degian external configurations" do
  set :host3_ip, "172.19."+get(:number).to_i.to_s+".41"
  set :host3_username, "root"
  set :host3_password, get(:host1_password).to_s
  set :host3_domain, get(:host1_domain).to_s

  target "ping to <"+get(:host3_ip)+">"
  goto :localhost, :exec => "ping #{get(:host3_ip)} -c 1"
  expect result.find!("100% packet loss").eq(0)

  target "SSH port 22 on <"+get(:host3_ip)+"> open"
  goto :localhost, :exec => "nmap #{get(:host3_ip)} -Pn | grep ssh|wc -l"
  expect result.eq(1)
end

task "Debian student configurations" do
  shortname = get(:apellido1).to_s + get(:number).to_s + "h"
  target "Checking hostname -a <"+shortname+">"
  goto :host3, :exec => "hostname -a"
  expect result.equal?(shortname)

  domainname = get(:host3_domain).to_s
  target "Checking hostname -d <"+domainname+">"
  goto :host3, :exec => "hostname -d"
  expect result.equal?(domainname)

  fullname= shortname+"."+domainname
  target "Checking hostname -f <"+fullname+">"
  goto :host3, :exec => "hostname -f"
  expect result.equal?(fullname)

  username=get(:username)

  target "User <#{username}> exists"
  goto :host3, :exec => "cat /etc/passwd | grep '#{username}:' | wc -l"
  expect result.eq(1)

  target "Users <#{username}> with not empty password "
  goto :host3, :exec => "cat /etc/shadow | grep '#{username}:' | cut -d : -f 2| wc -l"
  expect result.eq(1)

  target "User <#{username}> logged"
  goto :host3, :exec => "last | grep #{username[0,8]} | wc -l"
  expect result.neq(0)

  goto :host3, :exec => "blkid |grep sda1"
  unique "UUID_sda1", result.value
  goto :host3, :exec => "blkid |grep sda2"
  unique "UUID_sda2", result.value
end

task "Debian network configurations" do
  goto :host3, :exec => "ip a|grep ether"
  mac= result.value
  log    ("host3_MAC = #{mac}")
  unique "MAC", mac

  target "Gateway <#{get(:gateway_ip)}>"
  goto   :host3, :exec => "route -n"
  expect result.find!("UG").find!(get(:gateway_ip)).count!.eq 1

  target "WWW routing OK"
  goto   :host3, :exec => "ping 88.198.18.148 -c 1"
  expect result.find!(" 0% packet loss,").count!.eq 1

  target "DNS OK"
  goto   :host3, :exec => "nslookup www.iespuertodelacruz.es"
  expect result.find!("Address:").find!("88.198.18.148").count!.eq 1
end
