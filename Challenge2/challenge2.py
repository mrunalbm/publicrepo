from bs4 import BeautifulSoup
import requests
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-c", "--count", type=int)

args = parser.parse_args()
noofarticles = int(args.count)
website = "https://news.ycombinator.com/"
    

requests_object = requests.get(website)
if requests_object.status_code == 200:
    BS_object = BeautifulSoup(requests_object.text, "html.parser")
    articles = BS_object.findAll("span", attrs={"class":"titleline"})
    bysites = BS_object.findAll("span", attrs={"class":"sitestr"})
    count = int(0)
    for article, bysite in zip(articles, bysites):
        count = count + 1 
        if count <= noofarticles:
            print(f'{count:2d}  {article.text:100} from {bysite.text:20}')
        else:
            break
else:
    print ("URL did not work. Please check")



    

