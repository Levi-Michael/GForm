import requests

x = requests.get('https://google.com')
print(x.status_code)