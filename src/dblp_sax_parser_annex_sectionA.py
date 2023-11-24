# Import the necessary packages
import os
import xml.sax
import gzip
import re
import pandas as pd

# Set the working directory to where the DBLP dataset is located
os.chdir('C:/Users/geneh/Desktop/DBLP')

# Define a SAX parser class for the DBLP dataset
class DBLP_Parser(xml.sax.ContentHandler):
    
    def __init__(self):
        # Initialize variables for XML parsing
        self.path = []  # Stack to track the current XML path
        self.text = []  # Accumulate text data within XML tags
        self.row = {}   # Temporary storage for data of a single entry
        self.articles = [] # List to store all parsed articles
        self.record_count = 0 # Counter for processed records

        # Define valid elements and their respective data types
        self.valid_elements = {"article", "inproceedings", "proceedings", "book", "incollection", "phdthesis", "mastersthesis", "www", "person", "data"}
        self.element_features = {
            "address": "str", "author": "list", "booktitle": "str", "cdrom": "str",
            "chapter": "str", "cite": "list", "crossref": "str", "editor": "list",
            "ee": "list", "isbn": "str", "journal": "str", "month": "str",
            "note": "str", "number": "str", "pages": "str", "publisher": "str",
            "publnr": "str", "school": "str", "series": "str", "title": "str",
            "url": "str", "volume": "str", "year": "str"
        }

    # Function to calculate the total number of pages from a page range
    def page_counter(self, page_info):
        total_pages = 0
        for part in re.split(r",", page_info):
            sections = re.split(r"-", part)
            if len(sections) > 2:
                continue
            try:
                sections = [int(re.findall(r"[\d]+", sec)[-1]) for sec in sections]
            except IndexError:
                continue
            total_pages += 1 if len(sections) == 1 else sections[1] - sections[0] + 1
        return str(total_pages) if total_pages != 0 else ""

    # Called by SAX parser when it encounters the start of an element
    def startElement(self, tag, attributes):
        self.path.append(tag)
        
        # Initialize a new row when encountering a valid publication element
        if tag in self.valid_elements:
            self.row['mdate'] = attributes.get('mdate')
            self.row['publtype'] = attributes.get('publtype')
            self.row['key'] = attributes.get('key')
            self.row['type'] = tag  # Add publication type
        
        # Print progress every 10 million records
        self.record_count += 1
        if self.record_count % 10000000 == 0:
            print(f'Processed {self.record_count} records so far.')

     # Called by SAX parser for character data within elements
    def characters(self, content):
        self.text.append(content.strip())

    # Called by SAX parser when it encounters the end of an element
    def endElement(self, tag):
        full_text = " ".join(self.text).strip()  # Combine accumulated text

        # Process and store the text data based on the tag type
        if tag in self.element_features:
            if self.element_features[tag] == "str":
                if tag == "pages":
                    full_text = self.page_counter(full_text)
                self.row[tag] = full_text
            elif self.element_features[tag] == "list":
                self.row.setdefault(tag, []).append(full_text)
        
        # Finalise and store the row when the end of a valid element is reached
        if tag in self.valid_elements:
            self.articles.append(self.row.copy())
            self.row.clear()

        # Announce completion when the end of the document is reached
        if tag == 'dblp':
            print("Completed parsing XML. All entries processed.")
        
        # Reset the text accumulator and update the path
        self.text.clear()
        self.path.pop()

# Instantiate the parser and set the content handler
parser = xml.sax.make_parser()
handler = DBLP_Parser()
parser.setContentHandler(handler)
with gzip.open('dblp.xml.gz', 'rt') as f:
    parser.parse(f)

# Convert parsed data into a DataFrame and save it as CSV
dblp = pd.DataFrame(handler.articles)
dblp.to_csv('dblp.csv')

#Handle irregularies in dblp.csv and removal of type =‘data’, ‘mastersthesis’, phdthesis’, ‘www’which care not relevant to our queries
dblp = pd.read_csv('dblp.csv',index_col=0,header=0)
types_to_remove = ['data', 'mastersthesis', 'phdthesis', 'www']
dblp = dblp[~dblp['type'].isin(types_to_remove)]

years = dblp['year']
for i in range(len(years)):
    tempyear = years[i]
    if isinstance(tempyear,str):
        dblp.loc[i,'year'] = tempyear.replace(' ','') # for issues like '2 015'
    else:
        if np.isnan(tempyear):
            dblp.loc[i,'year'] = 'NaN' # for values with 'np.nan'
del years
del tempyear
dblp.to_csv('dblp.csv',header=True,index=True)

#Creation of Author Table
# Assume author_df is your original DataFrame with an 'author' column containing lists of authors
df.reset_index(inplace=True)
df.rename(columns={'index': 'pubid'}, inplace=True)
author_df = df[['pubid', 'author', 'title']]
author_df_exploded = author_df.explode('author').reset_index(drop=True)
# Now, since 'author' contains individual authors per row, we can get unique authors
authors = author_df_exploded['author'].unique()
# Create a mapping of authors to unique IDs
author_mapping = {author: i+1 for i, author in enumerate(authors)}
# Map the authors in the exploded DataFrame to their unique IDs
author_df_exploded['AuthorID'] = author_df_exploded['author'].map(author_mapping)
author_df_exploded.to_csv('author.csv')


#Creation of Authored Table - Linking Author Table to Publication Table

# Loading the previously saved author data
author = pd.read_csv('author.csv',index_col=0,header=0)
# Sorting by 'AuthorID' and removing any duplicate entries
author.sort_values('AuthorID',inplace=True)
author.drop_duplicates(subset='AuthorID',inplace=True)
# Extracting a table of unique authors and their corresponding IDs
unique_author = author.loc[:,['author','AuthorID']]
# Saving this unique author table, which can be used to link authors to publications
unique_author.to_csv('unique_author.csv',index=True,header=True)

