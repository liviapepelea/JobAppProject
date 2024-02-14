require 'watir'
require 'watir-scroll'
require 'webdrivers'
require 'rubygems'

Given('I open CSGOEmpire website') do
  binary_path = 'C:\Program Files\Mozilla Firefox\firefox.exe' # Update this with the correct path on your system

  # configure Firefox options
  options = Selenium::WebDriver::Firefox::Options.new
  options.binary = binary_path

  # initialize the Firefox browser with specified options
  browser = Watir::Browser.new :firefox, options: options

  browser.window.maximize

  # open the website
  browser.goto 'https://csgoempire.com/roulette'

  # store the browser instance in a global variable for further use
  @browser = browser
end

# Step purpose: to input a custom bet amount
Given('I input the value of bet amount as {string}') do |bet_amount|
  # set a variable that contains bet amount locator
  bet_amount_locator = @browser.element(xpath: "//input[@placeholder='Enter bet amount...' and @type='text']")

  # input the bet amount
  bet_amount_locator.send_keys bet_amount

  # check if the input field was changed with desired amount
  if bet_amount_locator.attribute('value') != bet_amount
    raise "Error: The input field was not changed to desired bet amount! Expected value: #{bet_amount}, Actual value: #{bet_amount_locator.attribute('value')}."
  end
end


And('I quit the browser') do
  @browser.quit
end


# Step purpose: to click either the 'Max' or 'Clear' button
And('I click {string} button') do |max_or_clear_button|
  begin
    case max_or_clear_button

    when 'Max'
      # set a variable for max  button locator for further user
      max_button = @browser.element(xpath: "//div[@class='bet-input__controls']//button[text()='Max ']")
      raise "Error: Max button not found!" unless max_button.exists?

      max_button.click

    when 'Clear'
      # set a variable for clear button locator for further user
      clear_button = @browser.element(xpath: "//div[@class='bet-input__controls']//button[text()='Clear ']")
      raise "Error: Clear button not found!" unless clear_button.exists?

      clear_button.click
    else
      # raise error for an invalid button name
      raise "Error: Invalid button name!"
    end
  rescue StandardError => e
    # raise an error if any other exception occurs
    raise "Error clicking '#{max_or_clear_button}' button: #{e.message}"
  end
end

# Step purpose: randomly generate a number of button clicks with buttons array
# and compute the bet value in automation to compare it with the value after the bet amount was modified by clicking a button
And('I click a random number of buttons that modify the bet') do
  # define an array of the buttons that can modify the value of the bet and their respective values
  buttons = ['+ 0.01', '+ 0.1', '+ 1', '+ 10', '+ 100', '1/ 2', 'x 2']

  # generate a random number of button clicks between 10 and 20
  num_clicks = rand(10..20)

  # print the number of buttons that will be clicked
  puts "#{num_clicks} buttons will be clicked."

  # get the initial bet value from the webpage for the first iteration
  @initial_bet_value = @browser.element(xpath: "//input[@placeholder='Enter bet amount...' and @type='text']").attribute("value").to_f
  puts "Initial bet value on webpage is #{@initial_bet_value}"

  # loop for the specified num_clicks value
  num_clicks.times do
    # choose a random button from the array
    random_button = buttons.sample
    puts "#{random_button} operation was randomly chosen."

    begin
      # click the randomly selected button
      button_element = @browser.element(xpath: "//div[@class='bet-input__controls']//button[text()='#{random_button}']")
      button_element.click

      # verify the correctness of the bet amount after clicking the button and compute the new bet value
      compute_bet_value(@browser, random_button)
    rescue StandardError => e
      # raise an error if any other exception occurs
      raise "Error clicking '#{random_button}' button: #{e.message}"
    end
  end
end

# Method purpose: compute the bet amount to be able to compare it with the result from GUI to check if the modify bet amount buttons work properly
def compute_bet_value(browser, button)
  begin
    # determine the previous bet value automation based on the iteration
    previous_bet_value_automation = if @computed_bet_value.nil?
                                      @initial_bet_value
                                    else
                                      @computed_bet_value
                                    end

    # split the button to separate the operator from the value
    # the special case of operator "1/ 2" should also be handled
    operator, value = if button == "1/ 2"
                        ["/", 2.0]
                      else
                        button.split(' ')
                      end
    value = value.to_f

    # compute the expected bet value based on the operator and value
    current_bet_value_automation = case operator
                                   when '+'
                                     previous_bet_value_automation + value
                                   when 'x'
                                     previous_bet_value_automation * value
                                   when '/'
                                     previous_bet_value_automation / value
                                   else
                                     raise "Error: Unsupported operator '#{operator}'"
                                   end
    current_bet_value_automation = current_bet_value_automation.round(2)

    # print out the computed expected bet value
    puts "Computed expected bet value: #{current_bet_value_automation}"

    # call the method to verify the bet value
    verify_bet_value(browser, current_bet_value_automation)

    # update the computed bet value for future iterations
    @computed_bet_value = current_bet_value_automation

    current_bet_value_automation
  rescue StandardError => e
    # raise an error if any other exception occurs
    raise "Error computing bet value: #{e.message}"
  end
end

# Method purpose: compare bet amount computed in automation with the result from GUI to check if the bet amount is modified and calculated properly
def verify_bet_value(browser, current_bet_value_automation)
  # get the current bet value from the webpage
  sleep 1
  browser.element(xpath: "//span[text()='Previous Rolls']").click
  current_bet_value_page = browser.element(xpath: "//input[@placeholder='Enter bet amount...' and @type='text']").attribute("value").gsub(',', '.').to_f
  puts "Current bet value on webpage is #{current_bet_value_page}"

  begin
    # verify if the computed bet value matches the value on the webpage
    puts "Comparing Current bet value from UI: #{current_bet_value_page} with Current bet value computed in automation: #{current_bet_value_automation}"
    raise "Error: Bet amount is incorrect. Expected: #{current_bet_value_automation}, Actual: #{current_bet_value_page}" if current_bet_value_page != current_bet_value_automation

    # log a message indicating the correctness of the bet amount
    puts "Bet amount is correct: #{current_bet_value_page}"
    puts ""

  rescue StandardError => e
    # raise an error if any other exception occurs
    raise "Error verifying bet amount correctness: #{e.message}"
  end
end
