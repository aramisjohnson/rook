# Prerequisites
1. GO installed and configured on your development box
2. Git client installed on development box
3. Github account created

# Creating a Fork

From your browser navigate to <a href="https://github.com/rook/rook">http://github.com/rook/rook</a> and click the "Fork" button. 

# Setting Up Your Development Box

### Clone Your Fork to Your Development Box

Open a console window on your development box and do the following;
```bash
#Create the rook repo path
mkdir -p $GOPATH/src/github.com/rook

#navigate to the local repo path and clone your fork
cd $GOPATH/src/github.com/rook

#Clone your fork, where USERNAME is the name of your repo you forked rook too
git clone git@github.com:USERNAME/rook.git

cd rook
```

# Keeping Your Fork Up to Date
To keep your fork up to date with rook/rook do the following;

```bash
#Add 'upstream' rook/rook repo to list of remotes
git remote add upstream https://github.com/rook/rook.git

#Verify remote is created
git remote -v

# Fetch from upstream remote
git fetch upstream

# View all branches, including those from upstream
git branch -va
```

Checkout your forked branch and merge it with the upstream repo's master branch:

```bash
# Checkout your master branch and merge upstream
git checkout master
git merge upstream/master
```

# Working
To begin add a a feature of to make a bug fix do the following.

## Create a Branch

From your console window, create a new branch based on your fork and start working on it:
```bash
# Checkout the master branch - you want your new branch to come from master
git checkout master

# Create a new branch named newfeature (give your branch its own simple informative name), no numbers please
git branch newfeature

# Switch to your new branch
git checkout newfeature
```

# Submitting a Pull Request
Now that you have created your new feature or fixed and issue below is the process for adding your changes to 
rook/rook.

## Regression Testing
All pull requests must not cause the results of the unit and e2e smoke tests to regress. These tests automatically
get ran as a part of the build process and the results of these tests along with code reviews determine whether
your request will be accepted. It is prudent to run both locally on your development box prior to submitting a pull request.

### Running the Unit Tests
From the root of your local rook repo execute the following;
```bash
make test
```
The unit tests will run and the output will tell you if the results.


### Running the Smoke E2E Tests
For instructions on how to execute the end to end smoke test suite, 
follow the instructions at 
<a href="https://github.com/rook/rook/blob/master/e2e/README.md">README.md</a>

## Cleaning Up Your Work
Rebase your development branch to simplify merging with rook/rook
```bash
# Fetch upstream master and merge with your repo's master branch
git fetch upstream
git checkout master
git merge upstream/master

# If there were any new commits, rebase your development branch
git checkout newfeature
git rebase master
```

Typically we recommend if you have numerous smaller commits in a single branch, please do
squash your smaller commits down into a single or small number of larger related commits.
```bash
# Rebase all commits on your development branch
git checkout 
git rebase -i master
```
This command will open your default editor and you can interactively select to squash your commits.

## Submitting
Once you've committed and pushed all of your changes to GitHub, 
go to the page for your fork on GitHub, select your development branch, 
and click the pull request button. If you need to make any adjustments to 
your pull request, just push the updates to GitHub. Your pull 
request will automatically track the changes on your development branch and update.