Welcome to the Docuemntation README!!

When creating a new file please follwo the structure used in the ExampleTextStructure.docx.
If you follow the ExampleTextStructure file will be easy to convert it from .docx to .rst.


Once installed Pandoc you can convert from docx to rst using this simple code.

The conversion is made with pandoc (https://pandoc.org/).
	- To covert from .docx to .rst launch in the terminal:
		`pandoc File.docx -f docx --extract-media Path_where_to_store_iamges -t rst -o File.rst`

	- To convert back to .docx:
		`pandoc File.rst -f rst -t docx -o File.docx`

The Code_blocks_fixer.py is an utulity python script that converts all the codeblocks that are created "general" to python or R specific.
To launch just pass the file and the code type.