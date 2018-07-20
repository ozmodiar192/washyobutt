# washyobutt
## Introduction
Lately my job has been writing ansible to install and configure Weblogic, JBoss, Endeca, and apache environments for customers who run ecommerce sites based on Oracle Commerce, or ATG.  It’s a fine job; I’ve gotten comfortable with ansible and I’ve learned some things along the way.

Recently my whole team congregated at our corporate office.  Most of us are remote, so when we get together it’s a whole year of socialization, planning, and discussion condensed down to a week.  There’s people who work on a variety of technologies; AEM, ATG, Sitecore, and pretty much any other technology you can host an ecommerce website on.

My company seems to hire young and enthusiastic people.  It’s something I love about it.  During our annual powow, I noticed was almost everyone had a big idea for how the team should function; some new method of dealing with work, some way to push our offering into the future.  Some of them will blossom beautifully into existence, and some are what you can only call Devops fanfiction.  I’ve had enough of these ideas to know that most of them won’t happen.

So this is my newest technology project that won’t happen.  I bought the washyobutt.com domain on a lark about 6 months ago after watching the Public Enemy “I Can’t do Nuttin’ for Ya, Man” video on youtube.  I never really had any good use for the domain.  I still don’t, but that’s not going to stop me from building the most over-engineered, devopsy site I can.

## Tweeting My Commits

The first thing I did was register @washyobutt on twitter, though the website.

### About Git Hooks
I wanted to post all my commit messages to Twitter for absolutely no reason other than dicking around with git hooks.  In git, you write code locally on your computer, then “commit” it, and push it to github where it’s made available.  A hook is a script that git executes automatically during the commit/push process.  When and where they run is customizable.  There are hooks that run client side (on your local machine) and server side (hooks that run on the github server).  The kind you need depends on what you’re trying to accomplish and what you need.

In my case goals are:
* I want to publish my commit messages to twitter automatically
* I want this hook to be checked in with my code, so I don’t have to re-write it or copy it to every machine I work on.
* I want it to work in Mac, Linux, and Windows.

Server side hooks are based around “push”, when you actually send your committed code up to github.  Client-side hooks are generally based around “commits”, which is where you tell your local git repository that something has changed and you want to keep it.  I usually work with ansible tower/awx, which pulls from git every time it  runs.  I’m used to committing and then pushing every change so I can test it.  Having a bunch of un-pushed commits isn’t going to work in that situation because unpushed code only exists locally, and awx is pulling from the github server.  With washyobutt, I can work locally and do my testing without constantly pushing.

In the spirit of how hooks work, I’m going to use client side hooks.  There are a few events where hooks are called.  In my case, I’m just pushing information around; I’m not enforcing any policies or affecting my commits in any way.  Therefore, my script will be post-commit.  I do the commit, git does whatever it does, and then the hook will run.

Since I said I want my hooks to be portable, I should probably not write them in bash.  I use a mac for work, Ubuntu for projects, and Windows for my home PC.  I won’t be using my work laptop for this, but I’d like to have a hook that I can run on any computer I happen to be in front of.  I like python, and it’s platform independent, so I’m going to use that.  

### The Twitter API and OAuth
I’m going to take a break from setting up the hooks to learn about the twitter API, since that’s what I’m going to be talking to.  I don't want to open a browser and post my tweets, so I need to send them directly through the twitter API.  To do this, I need to set up OAuth keys, which will allow me to authenticate with twitter.

#### The Keys

To get the keys and create the application, you go to https://apps.twitter.com/ and sign in with your twitter account.  There’s a big-ass “Create new App” button.  Press that and you’ll get a setup form.  I filled it out, but left callback URL empty because I don’t want Twitter to return me to any site in particular.

Once you create your app, you’ll see your Consumer Key.  The twitter API uses oauth.  The concepts I’m talking about apply to oauth-based api’s, although the exact terminology may differ slightly.  

Right next to the Consumer Key, you’ll see a link that says “Manage Keys”.  This is where we’re going to create the actual keys that will let us post shit to twitter.  If you click in there, you’ll see a button at the bottom to generate access tokens and secrets.  Copy those down and keep them safe.

You’ll end up with four keys at the end.  Here’s what they are and what they’re for:

Consumer Key: This tells twitter what application you’re talking to.  My application does one thing - posts commit messages from github.  Therefore, my user and my application are pretty-much the same.  If you consider a large application or a research project that’s posting, collecting, or doing something with tweets, it becomes more clear why twitter needs to know the exact application you’re trying to talk to.

Consumer Secret: This is the private half of the consumer keys.  It’s not transmitted like the consumer key is.  You know this, and twitter knows this.  It’s analogous to your password.  It’ll be used later to compute authentication information.

Access Token: Since my “app” is acting on my behalf and posting tweets as me, I need an access token.  You use your consumer keys to tell twitter “I have access to use the washyobutt application”, so now you need to use the access token to tell it “It’s me, Matt, and I’m allowed to post to my washyobutt account”.  The consumer key is application-based, and the access token is user-based.

Access Token Secret: This is the secret part of your access token.  It’s pretty-much the same deal as the consumer secret; it’s the private half of the exchange.

#### Understanding the OAuth Headers

I’ll be talking to the twitter REST interface.  I’m going to use a library specifically for this purpose, but it’s good to understand what’s happening behind the scenes.  According to the twitter docs, you can post like a tweet like this:

```
POST https://api.twitter.com/1.1/statuses/update.json?status=This%20is%20my%20post
```

The %20 are url-encoded, or percent-encoded, spaces.  You can url encode/decode using an online tool like https://www.url-encode-decode.com/.

That’s simple, but first you have to authenticate by adding some extra HTTP Headers:
```
Authorization:
OAuth oauth_consumer_key="xvz1evFS4wEEPTGEFPHBog",
oauth_nonce="kYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg",
oauth_signature="tnnArxj06cWHq44gCs1OSKk%2FjLY%3D",
oauth_signature_method="HMAC-SHA1",
oauth_timestamp="1318622958",
oauth_token="370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb",
oauth_version="1.0"
Content-Length: 76
Host: api.twitter.com
```

This is from the twitter API documentation; it’s wrapped here for readability.  Again, I’m going to use a 3rd party python library to do this work for me, but it’s worth taking some time to understand OAuth.  You can read about oauth until your eyes fall out, but I want to at least understand the headers for twitter and what they do.
 
The consumer key we talked about above - that’s what tells Twitter which application I am.

The nonce is a unique 32-character string that twitter uses to detect duplicate requests.  This needs to be random.

The signature is where things start to get interesting.  This is used to verify your access, your user, and also let’s twitter tell if your request has been altered in transmission.  It’s a computed value based on a hash of the request created with your secret information.  If you were to construct this, you’d take all the other parameters from both the http headers and the url, jam them all together and percent encode them.  Then you’d do the same with your sensitive information - your consumer secret and your oauth token secret.  Now you feed your jammed together encoded request and your jammed together sensitive information through a hashing algorithm to get a binary string, which you then convert base64.  Twitter will create the same sensitve string and use the same hashing algorithm verify your request.

The oauth signature method tells twitter what hashing algorithm you used to generate the signature.

The timestamp is the time that the request was created, in seconds since the unix epoc.  Twitter won’t post old tweets, or tweets from the future.

The Oauth token is the oauth token value from the apps.twitter.com site.

The oauth version is the version of oauth to use.  Twitter uses oauth 1.0, so this is always the same.

### Setting Up Git
Now that I understand the twitter API and I have my keys, I need to start on the actual hook.  

#### Creating a Local Repository
First I’m going to need a git repository.  I’ll start by initializing a new project in git with git init. 
```
mkdir -p ~/Projects/wyb
cd !$ 
git init
```
!$ is my favorite bash shortcut.  It's a built-in for the last argument of your previous command.  In the example above it would exand to cd ~/Projects/wyb.  Very useful.

I want to keep all my shit in one place (~/Projects/wyb), so I’ll use this for the whole project.  However “all my shit” includes sensitive data like api keys and a directory of misc notes and templates for my own reference, so I better create a .gitignore file in my project so I don’t end up checking it in.

```
#Exclude private and reference directories
/private
/notes
```

Now I have a local git repository, but nowhere to push it, so I need a repository on github.com to push my stuff. 

#### Creating the Repository on Github.
Log into github and push the big, green “New Repository” button.

With that complete, I need access to it.  I have existing projects and keys, but I’ll create a new ssh key for this project.
```
ssh-keygen -f ~/.ssh/wyb -t rsa -b 4096 -C “mattdherrick@gmail.com”
```
That creates a public and a private key in my home .ssh directory, encrypted with rsa with a size of 4096 and my email address as an identifier.

Now that I have a public (.pub!) key, I’ll add it to my github account under Profile > SSH and GPG keys.

#### A Quick Sidetask in Bash
Before I do that, I’m going to install xclip.  Xclip will let you copy terminal output directly to ubuntu’s clipboard.  Since 99% of what I do is copying and pasting, I’m going to use it a lot.
```
sudo apt-get install xclip
```

By default, you need to middle click to paste from xclip because it goes to a different buffer by default.  I want it to go to the actual clipboard because I was raised with ctrl + v, not this middle click bullshit.  I’m going to put an alias in ~/.bash_aliases

```
alias pbcopy=’xclip -selection clipboard’
```

Why pbcopy?  I use a mac most of the time, and it’s the command in OSX to copy output to your clipboard.  I’m not smart enough to keep track of the platform I’m working on.  If you were some kind of OS purist or had any principles at all, you'd probably just alias 'xclip' to 'xclip -selection clipboard'.


#### Back to Github
Now I’ll get my public key, and paste it into my github profile under “SSH Keys”.  Part of the reason I'm a stickler for xclip is that keys are sensitive to extra spaces and characters.  By using xclip, I'm sure I'm not dragging my mouse over an extra whitespace or grabbing part of my command prompt.

```
cat ~/.wyb.pub | pbcopy
```

Create a new key, give it a name, and paste it in.  Now I should be able to push from my local github repo to my remote repo.

Most people use github by memorizing a few commands, and then using them until something goes horribly wrong.  It’s a lot to unpack and understand, but I’m going to touch on the high level concepts a bit as it pertains to what I’m doing.

I have a local github repository that I made with git init, and a remote github repository I created through github.com.  I need to hook them together by adding the github repo as the remote.  The other (easier) way to do this is create the repo on github and then clone it, but I think this way is conceptually more clear.  

A remote is exactly what it sounds like; a remote github repository that you want to push to.  Here’s the command:

```
git remote add origin https://github.com/ozmodiar192/washyobutt.git
```

“Git remote add” makes sense, but what the fuck is origin?  You’ll see origin a lot in the git world; it’s the default label for the remote repository on your local system.  I could name it anything.  And if I set up my project on a different computer, I could name it the same or completely differently.  It doesn’t matter.  I use it because it’s usually named that way in examples and on stackoverflow, and most of what I do is copying and pasting out of stack overflow.

So now I should have my git repos hooked up, so I’ll add a README.md file.  That’ll display on the github page.  Eventually it’ll be this document, but for now I’ll put some dummy text in there.  I’ll edit the file and then do
```
git add *
```
If I changed a bunch of files and only wanted a subset, I would use a different pattern in my add command, but this is what I use most of the time since I tend to do iterative testing.  Now I’ve got the file added to my project, I’ll commit it.
```
git commit -m “Initial edits to readme.md”
```
-m is the comment I want to use.

So I have my file added, and I told git it’s something I want to commit.  Now I need to push it up to github.

The main branch in git is called “Master”.  Right now I’m working on master, but eventually, when I’m adding new functionality, I’ll probably branch.  For the time being I need to tell git that I want this to go on the master branch.
```
git push --set-upstream origin master
```
That means push it, and set it up to go to the master branch of origin, which you recall is the alias for the remote repository.  If I had named my remote repository “washyobutt” and I were on branch “firstbranch”, I’d do git push --set-upstream washyobutt firstbranch.

Now I’m able to get stuff into github.

### Setting up Python and Writing the hook
I’m going to break this up into two sections - Writing a hook in python that gets my last commit message, and then building out the twitter api stuff.

Hooks are stored in, and run out of, the .git/hooks directory, which doesn't get checked in.  There’s some samples in there when you create you project.  I want to include the hooks in the actual source code because I want to have all the ridiculous work I did available.  Therefore, I’ll create a hooks directory in my project, and then symlink it to the .git/hooks directory.  

The downside here is that I’ll need to remember to do this every time I check out the project.  I may go back and find a very complicated solution to this simple problem later.  For now I'll move the built-in samples from the /.git/hooks directory to /hooks, and then link /hooks back to /.git/hooks.

I determined earlier that I’d use a post-commit hook, so my file needs to be named post-commit.  You can’t name the hook whatever you want, which is a bummer because thetwittercommitter has a nice ring to it.  Also note that you can’t have a file extension.

#### Setting up Virtualenv

Python 2.7 is on my laptop already, but I want to set up virtualenv.  VirtualEnv lets you manage different python installations; I highly recommend it.  I already have the python package manager, pip, installed.  If you don't, the package is something like python-pip.

```
sudo pip install virtualenv
```

You have to use sudo for this part because the built-in python installation puts packages in a directory that isn't writable except by root.  We’ll fix that with virtualenv.

Now we’ll create a virtual environment for python 2.7, which is what’s on my machine by default.  Or maybe I put it on there.  I don’t remember.
```
virtualenv python27
```
That’ll create the environment in ~/python27.  Now I need to tell Ubuntu I want to use it

```
source ~/python27/bin/activate
```
Now when I use python, it’ll use the copy there.  Furthermore, I can write there, so I don't need to use sudo for everything.  I want this to be my default python installation, so I’ll add the command to source the activate script into my ~/.bash_profile.  Later, if I start messing with more installs of python, I might take this out.

The thing I don’t like is that virtual env adds the name to my terminal prompt:
<(python27) matt@ubuntu-tpad:~/python27/bin$>

To get rid of that, I’ll comment out the section in the activate script that references PS1, which is the default prompt.  I’ll re-source the file, and it goes away.  Now I can run pip without sudo.

#### Installing the Python Libraries

```
pip install tweepy
```

I also want to store my sensitive shit in a properties file in my private directory, which I added to my .gitignore earlier.  I’m going to use the ConfigParser lib to do that.
```
pip install configparser
```

Here’s my initial stab at a hook.  Since everything will be in github, I won't paste it in here, but this is a transitory file to show the basic idea.
```
#!/usr/bin/env python
#.git/hooks/post-commit
from subprocess import check_output

commitmsg = check_output(["git", "log", "-1"])
print(commitmsg)
print(len(commitmsg))
```

It uses the python subprocess check_output command to execute and get the output from the git command “git log -1”, which shows the last commit.  I also write out the length because I want to make sure my commit messages are less than the 280 character limit of twitter.  This is just my placeholder, so I’ll handle the output later.  I tested this and it worked fine.

So now I need to get talking to twitter.  I had previous thought about doing this all from scratch using the built-in Python urllib, but there are so many twitter api libs for python it seems stupid and inefficient to reinvent the wheel.

The working script is up at github.  My sensitive data file is formatted like this, for your reference:
```
[Consumer]
ConsumerKey=mykey
ConsumerSecret=mysecret

[Owner]
Owner=washyobutt
OwnerID=myownerid

[Access]
AccessToken=myaccesstoken
AccessTokenSecret=mytokensecret
```


## AWS
Now I need to actually start building something.  It seems like everyone uses aws, so I’ll start there.  At this time, I’m going to spin up a single instance, but I’m going to do everything in terraform because that’s what people on stackoverflow do.

### Terraform
Terraform is a way to represent your aws infrastructure as code.  It seems more complicated than it is; I’ve found it be pretty easy to use once you get going.  Between the aws docs and the terraform documentation, it's pretty easy to figure out what everything does.

I have an aws account already, but I don’t have my api keys.  Terraform is going to talk to the api, so it needs keys similar to what I used for the Twitter api, only there’s no consumer key because there’s only one ec2 application.

I’ll get them from my profile under My Security Credentials.  Again, I don’t want them in github, so I’ll put them in a tfvars file named terraform.tfvars, and add \*.tfvars to my .gitignore file

The secret vars file is in terraform/terraform.tfvars and looks like this:
```
accessKey = "myAccessKeyRightHere"
secretKey = "SuperSecretKeyRightHere"
```
The other option is not specify aws credentials, and store them in ~/.aws/credentials.  Terraform checks there by default, but I think I want to keep them in the project to have everything self contained.

You can’t just reference the tfvars directly; you need to set them actual variables in Terraform. I’ll put them into vars.tf.  I’m going to use vars.tf for all my variables, and any data that I’m pulling in externally and referencing later.  You can structure terraform however you want, because it’s smart enough to find all your references no matter where you store them.  

Before I start spinning shit up, I want to add a keypair and security rules so I can actually connect to these instances.  Eventually I’m hoping I won’t need to.

As you recall, I already generated a keypair for github.  If I use it for both github and AWS, and someone gets access to my private key file, they could then not only fuck with my github repo a bit, but they could get on my ec2 instances as well.  That sounds like bad news, but I’m not really storing these private keys anywhere except my laptop.  I’m not putting them on a shared drive or anything.  So, if someone got access to one, they’d likely have access to all of them anyway since they’re all hanging out in my .ssh directory.  If I had put passphrases on my keys, it might be a different story since there would be a layer of protection there, although ssh key passphrases could probably be brute forced pretty easily.

That paragraph might sound like my way of saying “fuck it”, but at least for now, wyb doesn’t have anything sensitive anyway so it doesn’t matter.  I try to think through security, even though I sometimes take the lazy way out.  “What if someone got this key?  What could they do?”  is a good question to continually ask yourself.  In this case, the answer is “break my website that doesn’t exist anyway” and “check more shitty code into my shitty code repository”.

I could manually put this keypair into the Amazon EC2 console and then associate it with instance when it comes up, but I want to create the keypair as part of my terraform job.  I created another new terraform file called “security.tf” where I’ll create all my security-related stuff.  Since my public key is public, I can put it right into terraform, in my vars file.

Now that I’ve got my key situation squared away, I also need a security group.  Security groups are pretty-much firewall rules for the ec2 instances.  Right now I’m going to use short-lived instances and log in manually, so I’ll need to open ssh (port 22).  

I could open it up to the world and rely on the security of my private key but that’s boring, so I’ll get my external IP address with a terraform http data source in my vars.tf file, which will call out to icanhazip.com to get my local machine’s external IP.  I love icanhazip.com; it returns your ip address with no extra formatting or bullshit.  I think it has a carriage return in it, though, so had to use the terraform chomp filter on it.  This may not be very sustainable for the long term, but since I’m dicking around at home and tearing things down right away, it’s a fun way to do it for now.  “Fun” being a very relative term.

Now I can create an entry for my ec2 instance, making sure to reference my key pair and security group.  This is in ec2.tf, along with the provider definition for aws that reads in my credentials.  I'll quickly go over the terraform syntax for this ec2 instance.

```
resource "aws_instance" "wyb-singleton" {
  ami             = "ami-2757f631"
  instance_type   = "t2.nano"
  key_name        = "wyb.pub"
  security_groups = ["allow_ssh"]
  tags {
    application = "washyobutt"
  }
}

```
The first line is telling terraform I want to create an aws_instance with a name of "wyb-singleton".  The types are all available in the terraform documents. The name is the name that terraform will use to reference the resource.  Some resources have both the terraform name, and a name for EC2 (like my security policy).  You can name them however you want.  Within the brackets are the configuration parameters for the resource type you're creating.  There are usually lots, and you can find them in the documentation.  Finally, you have 'tags', which are a way to organize your hosts within EC2.  You can use tags for filtering your resources, and also for billing.  I just gave mine a generic tag called "application" with a value of "washyobutt".



So if I run this, it works!
```
terraform plan
```
Shows what I expect, and if I run
```
terraform apply
```
Everything gets created.  If I do
```
terraform show
```
To get the public dns of my instance, I can log into it with
```
ssh -i ~/.ssh/wyb ubuntu@<myPublicDnsThatIJustGotFromTeraformShow>
```

Things are coming together nicely, however terraform has left it’s state files in my directory.  Terraform maintains the state in static files by default.  That’s fine if you’re like me; a single dude (ladies?) working solo on a small project.  I could safely add them to .gitignore and continue on my merry way, but I saw an article the other day that said “Why You Should Be Using Remote State in Terraform”.  I didn’t read it, but I can only assume the author made a compelling argument.

The main reason you’d want to mess around with the terraform state files is if you’re working on a project with other people.  Terraform needs that state file to be accurate, so you have to treat it with care.  If Sue Developer is trying to build with terraform the same time as Jane Developer, it’s going to go badly.  You can’t track it with git because you have no idea if someone else has updated the environment.

Luckily, we can use Amazon s3 to store our state file.  And we can create the s3 bucket with terraform.

#### Setting Up Terraform State

The high-level process for this is to create an s3 bucket, then tell terraform to store it's state there.  S3 is Amazon's file storage service.  They call an S3 object a "bucket", and that's a useful way to think of it. Once I have my state stored remotely, I'll set it up to use locking because that's what a lot of real people do.  If you have multiple people using terraform, you would want your state to lock so people can't fuck it up by running things simultaneously. Since I'm doing this solo, I'll have to find some other way to fuck it up.

I'm trying to keep this project cheap, so the idea of having a persistent s3 bucket out there is off-putting to me.  However, the tfstate is tiny, so if it costs anything at all, it'll be negligable.

It's a simple process to set this up; the best guide is https://medium.com/@jessgreb01/how-to-terraform-locking-state-in-s3-2dc9a5665cb6, but I'm going to do my best to complicate it.

## AWS IAM Setup
While looking into Bucket policies that I might want to add, I realized that my Amazon AWS account is set up with a root user only.  The root user is the one I use to sign to the AWS console.  Amazon recommends that you not use the root user for anything other than setting up IAM.  IAM is Identity and Access Management.  I'm going to implement a very simple IAM setup.

Log in to the amazon AWS console at https://console.aws.amazon.com and find the Security, Identity, and Compliance section.  Under there, click on IAM.  You'll see a handy little checklist that explains all the ways you suck at security; "Delete your root access keys", "Activate MFA", etc.  For now, I'm just going to create my IAM user and worry about making the Security Status thing happy later.

Click on Users, and add a user.  I'm going to name mine terraform.  I'm going to give it Programmatic Access because I don't want anyone fucking around in the console with the terraform user.  Once you start using terraform, you've sold your soul to it; you don't want to do some shit manually and some shit in the console because it'll create drift and fuck up your state.  You can import things to terraform that you created manually, but that's a sucker's game.

I'll create a group for "api-full-access" and assign the built-in AmazonECFullAccess and AmazonS3FullAccess policies.  Amazon will provide the access and secret keys, which I can update in my private information store and tfvars.  If you were inclined, you could construct a very detailed policy around terraform, but I have no need for that now.  My goal is to understand conceptually without doing a whole bunch of legwork.

In the spirit of IAM, I'll also create an administrative user and an administrator group with the "AdministratorAccess" policy.  I gave this group access to the console as well as the api.  From now on, I'll use this user to sign into the console.

This has knocked out two tasks on my security status checklist in the IAM section of the aws console; I may as well finish it off by creating an IAM password policy, setting up MFA on my root account, and nuking my root account access tokens.  I clicked on Apply and IAM password policy and then used the "Manage Password Policy" button.  I used good ol' fashioned common sense and created a password policy that will work for me.

To setup MFA and delete the access keys from my root account, so I signed out of my IAM account and back in with root, and went back to the iam section of the console and followed the prompts in the checklist. 

I decided I'd manage at least the initial two users outside of terraform.  It would be a tall order to make terraform create the user that runs terraform, and I don't really want to fuck with my administrative console user with terraform.  If I were inclined, I could import these resources into terraform and allow terraform to manage them (terraform import aws_iam_user.wybmatt wybmatt).  If I ever need more users, I'll manage them with terraform.

#### Back to S3

To set up my remote state bucket, I created an S3 bucket and then defined it as the backend for terraform.  I put this in a file called setup.tf; that's where I'm going to store all my terraform configuration stuff.  I also moved the aws provider in there.  I also followed Jessica G's advice and created a dynamo db table for state.

#### Dynamo DB

DynamoDB is an Amazon service.  There are roughly a billion different amazon services, and I'm going to try to use as many of them as I can.  By doing this, it'll allow me to name drop them in casual conversation with my nerd friends, and I'll list them as skills on my LinkedIn profile even though my understanding of them is rudimentary at best, negligent at worst.

DynamoDB is non-relatiional database service.  Traditional databases like Oracle and SQL Server are relational; they store data in columns and rows in tables.  I might have a table for users, and each user will have an ID that serves as the primary key for that user.  A primary key is a unique value for each row that serves as the main identifier for that resource.   I can then link that user to other tables in the database, like "email addresses" and "wrongs committed against me".  The primary key, userID, would be set to the  "foreign key" of the "wrongs" and "email address" table.

A non-relational database, or a nosql database, doesn't give a shit about maintaining relationships between data.  They store data in a variety of ways; in the case of DynamoDB, there are still tables, but instead of the tables being linked, they're inclusive lists of attributes.  Using my example above, I would have a table called "users", but the "users" table would contain attributes for "ID", "email address" and "wrongs commited against me".  This is a little more intuitive and more flexible, since I can really have any information I want in the table.  I can note that Barry smells like tortilla chips, and that Andrew has a geographic tounge, without the overhead of creating tables for "smells" and "upsetting personal attributes".  Note that, at least in DynamoDB, there is still one requirement; each record still uses a primary key!

Which brings me to what started me down this road - figuring out why the "hash key" for the terraform DynamoDB table I'm creating has to be "LockID".  Hash key and Partition key are the same thing - they're types of primary keys.  Terraform is written to look for a DynamoDB record with a primary key of LockID.

I also had to check why I need a type of "S", but that was a simpler concept.  S is for String, N is for Number, and B is for binary data.

#### Terraform Remote State Sucks

I commented out the backend resource from my setup.tf, ran a terraform apply to create the S3 bucket and dynamoDB table, then uncommented out the backend.  I had to go back to my IAM user and add the AmazonDynamoDBFullAccess policy, but otherwise it went smoothly.

To change the backend, I had to run terraform init again.  It failed due to a bug in Terraform.  Apparently the backend configuration doesn't use the same code as the rest of terraform.  It was failing on my security keys, which you recall I'm storing in a terraform.tfvars file that I have secured and gitignored.  It seems like the two options here are:
1) Put my credentials directly into the terraform setup.tf file
2) Put my credentials directly into the terraform init commmand

I did the latter, but this is yet another manual step I'll have to do if I ever change laptops or bring in more members on the Washyobutt team.  If you're a security-minded person, you would also edit your ~/.bash_history file and delete the commands containing your sensitive info from your history.
```
 terraform init -backend-config="access_key=MYACCESSKEYISMYOWNBUSINESS" -backend-config="secret_key=ThIsI5mYAc355K3YRiGh7H3R3F3LLA"
```

The good news is that this worked, the bad news is that it kind of sucks.  The problem comes when I want to destroy.  I specified 
```
    lifecycle {
      prevent_destroy = true
    }
```
on my S3 bucket, which is a smart thing to do.  However, when Terraform encounters this, it doesn't just skip destroying it.  It exits, errors, and stops processessing.  That's not what I want; I want to freely destroy without breaking my state file.  I tried removing prevent_destroy and that was an even bigger disaster as you might expect; it couldn't unlock the state file because I deleted it mid-way through the run,  and I had to convert back to local state in order to clean it all up.

If you're working on something that you're not tearing down, you wouldn't have an issue here.  You could just plunk along, happily adding infrastructure and updating your shared, locking, badass tfstate table.  But the thought of my singluar, nano-sized EC2 instance out there, robbing me of pennies every month, has my jimmies sufficiently rustled.

What to do now?  I think I'll create a subset of my terraform scripts with just the state backend setup shit, and then import the state into my main terraform setup.  I could also explicitly tell terraform to target certain types of resources, but as my project grows it'll be a pain in the ass to maintain.  If I could do an exclude on my setup.tf resources, or if terraform just continued on rather than exiting when it encountered my prevent_destroy stuff, I'd be fine.

#### Fixing Remote State

I spent a bunch of time trying to make remote state work.  My goal was to have the state infrastructure defined in terraform, but it just wasn't in the cards.  First I tried creating a new directory where I put only the state-related infrastructure (the s3 bucket, the dynamoDB table, and a backend for state).  That worked, until it came time to apply the rest of my infrastructure.  The issue was that the backend was now servicing two distinct terraform directories, so when I did "terraform plan" in my directory, it flagged my infrastructure shit for deletion because it was in the state file, but not defined in my current working directory.

I considered importing the objects, but that won't work either, because importing something puts it under the management of terraform.  That would put me right back to my original problem; I don't want to tear down my state-related infrastructure when I'm tearing down everything else.  I tried using different keys, but that didn't seem to work.  The "key" should be the path within the bucket where things are stored, but I wasn't sure how that works when you're using DynamoDB, and I honestly didn't spend a lot of time on it.

Eventually, I bit the bullet and manually created the dynamoDB table and S3 bucket in the console.  Then I defined the backend in terraform in my backend.tf file, and everything worked fine.  That leaves my S3 bucket and DynamoDB table out there, totally isolated from terraform, as long as I never import them.  I honestly think this is the best way to do it, even though I consider it a minor compromise to my intention of creating a fully self-contained infrastructure.  

Again, this would all work handily if you the terraform lifecycle option "prevent_destroy" just skipped a resource instead of blowing up and exiting.

## A VPC of My Own
When you spin up an EC2 instance or something on Amazon, it creates a default VPC for you.  This allows Amazon to shield you from the ugliness of routing, IP addressing, and Internet gateways.  You can continue on your default VPC happily, never realizing it even exists.

If your needs grow, you might find yourself in need of a more sophisticated networking setup.  My needs have not grown, however I wanted to set up a VPC from scratch for my washyobutt application, because I feel like using the default one robs me my IT legitimacy.  When you tell Amazon you're using a non-default VPC, shit suddenly gets real.  You have to make a routing table, populate it with routes, create your own Internet gateway, and start specifying an IP scheme for your environment.  Whether you use it or not, my advice is not to fuck with your default VPC.  Don't clean up the subnets, don't mess with the routes, just leave it alone.  A VPC doesn't cost you anything; it's what you put on it that costs you money, so the default VPC hanging out there with nothing on it isn't going to run up your Amazon bill.

I put all my VPC-specific settings in vpc.tf.  I also move everything to a per-vpc sub-directory from terraform.  That way, if I ever create a VPC, I can keep it's terraform configuration totally separate.  If you look through my terraform shit, you'll see the resources now reference a vpc by the variable "${aws_vpc.wyb_public.id}".  Terraform lets you work with friendly labels when you create things, but when it comes time to hook everything together you will find yourself using a lot of IDs, which you grab using that syntax.  ${resource_type.the_name_you_gave_it.the_attribute_you_want_which_is_usually_id_but_sometimes_not}.  Again, this looks impressive when you're digging around in terraform, but in practice it's pretty simple.

The hardest part is understanding the VPC conceptually.  It's basically a network segment, with it's own devices, routes, and everything a network needs to function.  Right now, mine is very simple.  A VPC, a single instance, a gateway to allow internet access, a subnet, and a default route.  Everything is cross-referenced in a variety of ways, which are spelled out pretty plainly in the terraform documentation.  There were two changes that weren't very intuitive and caused me some hassle; when I started using my own VPC, I had to convert my reference to the security_group (allow_ssh) to use the id instead of the name, and I had to start specifying how I want to address my instance because it stopped giving me a public IP by default.  Right now, I just assigned it a public IP address.  Eventually I may use NAT, or elastic IPs, or something else.
