Capistrano::Configuration.instance(true).load do  
  after "postfix:install", "pflogsumm:install"
end