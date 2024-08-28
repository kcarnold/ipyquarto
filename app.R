library(shiny)
library(shinyjs)
library(processx)

ui <- fluidPage(
  useShinyjs(),
  titlePanel("IPython Notebook Renderer"),
  sidebarLayout(
    sidebarPanel(
      fileInput("file", "Upload IPython Notebook (.ipynb)", accept = ".ipynb")
    ),
    mainPanel(
      textOutput("render_status"),
      downloadButton("download", "Download Rendered HTML")
    )
  )
)

server <- function(input, output, session) {
  # Reactive value to store the rendered HTML file
  rendered_html <- reactiveValues(file = NULL)
  
  observeEvent(input$file, {
    # Invalidate previous output
    rendered_html$file <- NULL
    output$render_status <- renderText("Rendering...")
    if (!is.null(input$file)) {
      # Create a temporary directory to store the rendered file
      temp_dir <- tempfile()
      dir.create(temp_dir)
      
      # Render the notebook to HTML
      file.copy(input$file$datapath, file.path(temp_dir, "notebook.ipynb"))
      processx::run("quarto", args = c("render", "notebook.ipynb"), wd = temp_dir)
      
      # Store the rendered HTML file
      rendered_html$file <- file.path(temp_dir, "notebook.html")
      
      # Update the UI to show the render status
      output$render_status <- renderText("Notebook rendered successfully!")
    } else {
      output$render_status <- renderText("No input")
    }
  })
  
  output$download <- downloadHandler(
    filename = function() {
      # Extract the basename without the extension
      gsub("\\.ipynb$", ".html", basename(input$file$name))
    },
    content = function(file) {
      file.copy(rendered_html$file, file)
    }
  )
}

shinyApp(ui, server)
