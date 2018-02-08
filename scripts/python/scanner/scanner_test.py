from scanner import Scanner
from scanner_handler import ScannerHandler

channel_managers = ['0x5368849cdeeb9db9145747178fa5d8b2fb0d0fa0', '0x1239af4d416de529889498283e057eb6eeee5c54']
campaigns = []

scanner_handler = ScannerHandler()
scanner = Scanner('http://35.227.236.24:80', scanner_handler, channel_managers, campaigns)
block_current = scanner.current_block()
print('Current block in dev blockchain: ' + str(block_current))
# scanner.start(1745007, 1000000) # campaign deploy test
# scanner.start(1745154, 1)
# scanner.start(2091000, 10000)
