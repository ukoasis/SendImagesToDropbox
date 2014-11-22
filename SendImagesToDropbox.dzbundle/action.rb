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
			if item !~ /^\..*/
				file_path = Pathname($items[0]) + item
				path << generate_random_name_file(file_path.to_s)
			end

		end
	else 
		# 1 item or More than 1 item dragged 
		$items.each do |item| 
			path << generate_random_name_file(item)
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

def generate_random_name_file file
	file_path = Pathname(file)
	file_extension = file_path.basename.to_s.split('.').last
	random_strings = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map { |i| i.to_a }.flatten
	random_file_name = (0..64).map { random_strings[rand(random_strings.length)] }.join + '.' + file_extension
	random_file_path = Pathname('/tmp/') + random_file_name
	FileUtils.cp(file, random_file_path)

	random_file_path.to_s
end
