#!/usr/bin/ruby

# Dropzone Action Info
# Name: SendImagesToDropbox
# Description: Share images via Dropbox by copying them to your Dropbox Public folder and putting the URL on the clipboard.
# Handles: Files
# Events: Dragged, Clicked
# Creator: Yuki Yamashina
# URL: https://github.com/ukoasis/SendImagesToDropbox
# OptionsNIB: DropboxLogin
# RunsSandboxed: No
# Version: 1.0
# MinDropzoneVersion: 3.0
# UniqueID: 10010

require 'set'
require 'base64'
require 'pathname'
require 'fileutils'

# Global variables for Dropbox settings
@dropboxPubDir = ""
@dropboxPublicBaseURL = "http://dl.dropbox.com/u/"

def dropbox?
	# Get Dropbox Public directory from the Dropbox database file, if this file is not present
	# Dropbox is most likely not installed
	if File.exist?(conf_path = ENV['HOME'] + '/.dropbox/host.db')
	  @dropboxPubDir = Base64.decode64(File.open(conf_path).read).match(/\/.+$/)[0] + '/Public'
	  return true
  else
    return false
  end
end

def dragged
	$dz.determinate(true)
	# Check if Dropbox is installed and set Public path
	if not dropbox?
		$dz.finish("Dropbox is not installed")
		$dz.url(false)
		return
	end

	# Handle Drag
	path = []
	if File.directory?($items[0])
		# 1 Folder was dragged
		Dir::entries($items[0]).each do |item|
			filepath = Pathname(item)
			file_extension = filepath.basename.to_s.split('.').last
			rundom_strings = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map { |i| i.to_a }.flatten
			rundom_file_name = (0..64).map { rundom_strings[rand(rundom_strings.length)] }.join + '.' + file_extension
			rundom_file_path = Pathname('/tmp/') + rundom_file_name
			FileUtils.cp(item, rundom_file_path)
			path << rundom_file_path.to_s
		end
	else 
		# More than 1 item dragged 
		# Create zip of all items and name it after the first item
		$items.each do |item| 
			filepath = Pathname(item)
			file_extension = filepath.basename.to_s.split('.').last
			rundom_strings = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map { |i| i.to_a }.flatten
			rundom_file_name = (0..64).map { rundom_strings[rand(rundom_strings.length)] }.join + '.' + file_extension
			rundom_file_path = Pathname('/tmp/') + rundom_file_name
			FileUtils.cp(item, rundom_file_path)
			path << rundom_file_path.to_s
		end
	end

	# Copy file to Dropbox Public dir and place create URL on Clipboard
	$dz.begin("Copying files ...")
	path.each do |file_path|
		Rsync.do_copy([file_path], @dropboxPubDir, false)
		$dz.url("#{@dropboxPublicBaseURL}#{ENV['user_id']}/#{File.basename(file_path)}")
		FileUtils.rm_f(file_path)
	end
	$dz.finish("URLs is now on clipboard")
end

def clicked
	# Check for Dropbox and set Public Directory path
	if not dropbox?
		$dz.determinate(false)
		$dz.finish("Dropbox is not installed")
		$dz.url(false)
	else
		# Open Finder at Public Directory using Applescript
		`osascript -e 'tell application "Finder"' -e 'activate' -e 'open folder\
		POSIX file "#{@dropboxPubDir}"' -e 'end tell'`
	end
end
