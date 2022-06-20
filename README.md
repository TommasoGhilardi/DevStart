# PhD-Documentation
Initial repo for the documentation project


We can use [google docs](https://drive.google.com/drive/folders/10-W5TSKCHtv_b4yg36qKRwXG_Ef78wQf?usp=sharing) to keep track of the documents and work toghether.
Once finished we can convert everythin to restructured text using [Pandoc](https://pandoc.org/).

Once installed Pandoc you can convert from docx to rst using this simple code:

`pandoc File.docx -f docx --extract-media Path_where_to_store_iamges -t rst -o File.rst`

You can also do the opposite using:

`pandoc File.rst -f rst  -t docx -o File.docx`
