*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Robocorp.Vault
Library             RPA.Dialogs
Library             RPA.Archive
Library             RPA.Robocorp.Vault


*** Variables ***
${website-URL}              https://robotsparebinindustries.com/#/robot-order
${ordersfile}               orders.csv
${modal}                    css:button.btn.btn-dark
${legs}                     xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input
${preview}                  id:preview
${robot-preview-image}      id:robot-preview-image
${TEMP_DIR}                 temp


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${ASSETS}=    Get Secret    secrets

    ${weburl}=    Get Webstore URL from the user

    #    Open the robot order website    ${ASSETS}[robotUrl]
    Open the robot order website    ${weburl}
    ${orders}=    Get orders    ${ASSETS}[csv]
    FOR    ${singleorder}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${singleorder}
        Wait Until Keyword Succeeds    10x    0.2 sec    Preview the robot
        Wait Until Keyword Succeeds    10x    0.2 sec    Submit the order
        #Store the receipt as a PDF file    ${singleorder}
        ${pdf}=    Store the receipt as a PDF file    ${singleorder}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${singleorder}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${singleorder}[Order number]
        Go to order another robot
    END
    Create a ZIP file of the receipts

[Teardown]    Log out and close the browser


*** Keywords ***
Get Webstore URL from the user
    Add heading    Robot Store URL
    Add text input
    ...    input_url
    ...    label=Enter the Robot Store URL
    ...    placeholder=Enter url here
    ${response}=    Run dialog

    RETURN    ${response.input_url}

Open the robot order website
    [Arguments]    ${url}
    Open Available Browser    ${url}

Get orders
    [Arguments]    ${URL}
    Download    ${URL}    overwrite=True
    ${orders}=    Read table from CSV    ${CURDIR}${/}${ordersfile}    header=True
    RETURN    ${orders}

Close the annoying modal
    Wait And Click Button    locator=${modal}

Fill the form
    [Arguments]    ${order}
    Wait Until Page Contains Element    id:root
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    ${legs}    ${order}[Legs]
    Input Text    id:address    ${order}[Address]

Preview the robot
    Click Button    locator=${preview}
    # Wait And Click Button    locator=${modal}
    # Wait Until Page Contains Element    id:root

 Submit the order
# Retry three times at half-second intervals
    Click Button    id:order
    Wait Until Element Is Visible    id:order-completion

Store the receipt as a PDF file
    [Arguments]    ${ordernum}
    ${receipt}=    Get Element Attribute    id:receipt    innerHTML
    Html To Pdf    ${receipt}    ${OUTPUT_DIR}${/}receipts${/}Order_${ordernum}.pdf

Take a screenshot of the robot
    [Arguments]    ${ordernum}
    Screenshot    ${robot-preview-image}    ${OUTPUT_DIR}${/}previews${/}robot_preview_${ordernum}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${ordernum}
    ${myfiles}=    Create List    ${OUTPUT_DIR}${/}previews${/}robot_preview_${ordernum}.png
    Open PDF    ${OUTPUT_DIR}${/}receipts${/}Order_${ordernum}.pdf
    Add Files To PDF    ${myfiles}    ${OUTPUT_DIR}${/}receipts${/}Order_${ordernum}.pdf    ${True}
    Close Pdf    ${OUTPUT_DIR}${/}receipts${/}Order_${ordernum}.pdf

Go to order another robot
    Click Button    id:order-another

Log out and close the browser
    Close Browser

 Create a ZIP file of the receipts
    Archive Folder With ZIP
    ...    ${OUTPUT_DIR}${/}receipts
    ...    ${OUTPUT_DIR}${/}orders.zip
    ...    recursive=False
    ...    include=Order_*.pdf
