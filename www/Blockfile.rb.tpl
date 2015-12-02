# bundle exec blocks build && sh -c "cd www; node_modules/grunt-cli/bin/grunt dev"

require 'pathname'

# Paths used in this Blockfile implementation
ROOT_PATH =  Pathname.new(__FILE__).parent.realpath
BLOCKS_PATH = ROOT_PATH + 'blocks'
BUILD_PATH = ROOT_PATH + '.blocks/build'

###################################################################################

# Define the directory where WebBlocks will place the final build products.
set :build_path, BUILD_PATH

# Include the opt page block, from whence all else should be included.
include 'ohmage', 'custom'

# This proc, which should be executed as "instance_exec(path, &autoload_files_as_blocks)" from within a block def,
# will load all files directly within the directory path, using the file name as the block name, and the extension to
# determine which type of file to implicitly load the file into the block as.
autoload_files_as_blocks = Proc.new do |path|
  Dir.entries(path).keep_if(){ |fp| File.file?(path + fp) }.each do |fp|
    case /\.[^\.]*$/.match(fp).to_s
      when '.js'
        block(fp.gsub(/\.[^\.]*$/, ''), required: true){ js_file fp }
      when '.scss'
        block(fp.gsub(/\.[^\.]*$/, ''), required: true){ scss_file fp }
    end
  end
end

# Define the "opt" block for this application.
block 'ohmage', :path => BLOCKS_PATH do |n|


  # Define the "config" block of variables and other non-runnable stuff.
  config = block 'config', :path => 'config' do |config|

    # For the config block, load all config files with their name as their block name
    instance_exec(BLOCKS_PATH + 'config', &autoload_files_as_blocks)

  end

  # Define the "custom_config" block of deployment customized elements.
  custom_config = block 'custom_config', :path => 'custom/<%= custom_block %>/config' do |site|

    # Define dependencies that should be loaded before the custom_config block.
    dependency config.route

    # For The custom_config block, load all custom_config files with their name as their block name
    instance_exec(BLOCKS_PATH + 'custom/<%= custom_block %>/config', &autoload_files_as_blocks)

  end

  # Define the "components" sub-block of general-purpose elements.
  global = block 'global', path: 'global' do |components|

    # Define dependencies that should be loaded before the site block.
    dependency custom_config.route

    # Components all depend on Normalize.css
    dependency framework.route 'normalize.css'
    dependency framework.route 'WebBlocks-visibility', 'hide'
    dependency framework.route 'WebBlocks-visibility', 'accessible'

    # For the components block, load all component files with their name as their block name.
    instance_exec(BLOCKS_PATH + 'global', &autoload_files_as_blocks)

  end

  # Define the "components" sub-block of general-purpose elements.
  components = block 'components', path: 'component' do |components|

    # Define dependencies that should be loaded before the site block.
    dependency global.route

    # For the components block, load all component files with their name as their block name.
    instance_exec(BLOCKS_PATH + 'component', &autoload_files_as_blocks)

  end

  # Define the "app" sub-block of site-specific elements.
  app = block 'app', :path => 'app' do |site|

    # Define dependencies that should be loaded before the site block.
    dependency global.route
    dependency components.route

    # For the site block, load all site definition files with their name as their block name.
    instance_exec(BLOCKS_PATH + 'app', &autoload_files_as_blocks)

  end

  # Define the "site" sub-block of site-specific elements.
  page = block 'page', :path => 'page' do |site|

    # Define dependencies that should be loaded before the site block.
    dependency app.route

    # For the site block, load all site definition files with their name as their block name.
    instance_exec(BLOCKS_PATH + 'page', &autoload_files_as_blocks)

  end

  # Define the "custom" block of deployment customized elements.
  custom = block 'custom', :path => 'custom/<%= custom_block %>/site' do |site|

    # Define dependencies that should be loaded before the site block.
    dependency page.route

    # For The custom block, load all custom files with their name as their block name
    instance_exec(BLOCKS_PATH + 'custom/<%= custom_block %>/site', &autoload_files_as_blocks)

  end

end