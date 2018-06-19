# Scratch with Git
A couple batch scripts that compress and decompress Scratch projects so they can be used properly with Git.

The format is that when they are uploaded, all project files except project.json are in a folder named assets. The project.json file is in the repository root. When the compile script is executed, it takes the extracted contents in this format and zips them back up into an SB2 file using 7-Zip, or PowerShell if 7-Zip couldn't be located. It works with 7-Zip installs as well as a 7za.exe file dropped in the same directory as the folder. For this reason, you should put 7za.exe in your .gitignore file if you plan to use 7za.exe. You may also want to put \*.bat in your .gitignore in case you don't want these files being uploaded with your project. If you don't upload these files with your project, you should probably put instructions on what to do with these files in noticeable font size.

Feel free to pull request if you come up with an improvement. Tag me on GitHub or Scratch (BASIC4U) if you use this tool, I'd love to see what you're doing with it!
