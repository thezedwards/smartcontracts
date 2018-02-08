from web3 import Web3, HTTPProvider, IPCProvider
from scanner_handler import ScannerCampaignEvent, ScannerChannelEvent, ScannerChannelSettleEvent, ScannerHandler
from contracts import contract_channel_manager_abi, contract_channel_manager_bin, contract_campaign_abi, contract_campaign_bin

from web3.utils.abi import (
    abi_data_tree,
)

some_valid_address = '0x40748f41945cc5a36ca470b9d19723731fdc589f' # to avoid contract.encodeABI() exception

method_hash_length = 10 # with '0x' at start

class Scanner:
    def __init__(self, connection, handler, channel_managers, campaigns):
        self.web3 = Web3(HTTPProvider(connection))
        self.handler = handler
        self.campaigns = campaigns
        self.channel_managers = []
        for channel_manager in channel_managers:
            self.channel_managers.append(channel_manager.lower())
        self.campaign_contract = self.web3.eth.contract(abi=contract_campaign_abi, bytecode=contract_campaign_bin)
        self.channel_manager_contract = self.web3.eth.contract(abi=contract_channel_manager_abi, bytecode=contract_channel_manager_bin)
        self.campaign_deposit_hash = self.campaign_contract.encodeABI('deposit', [0])[:method_hash_length]
        self.campaign_withdraw_hash = '0xffffffff' # self.campaign_contract.encodeABI('withdraw', [0])[:method_hash_length]
        self.campaign_channel_create_hash = self.campaign_contract.encodeABI('createChannel', ['', '0x', some_valid_address, some_valid_address, 0])[:method_hash_length]
        self.campaign_channel_settle_hash = self.campaign_contract.encodeABI('settle', [0, 0])[:method_hash_length]
        self.channel_approve_hash = self.channel_manager_contract.encodeABI('approve', [0, some_valid_address])[:method_hash_length]
        self.channel_block_part_hash = self.channel_manager_contract.encodeABI('setBlockPart', [0, 0, '0x'])[:method_hash_length]
        self.channel_block_result_hash = self.channel_manager_contract.encodeABI('setBlockResult', [0, 0, '0x', 0])[:method_hash_length]
        self.channel_block_settle = self.channel_manager_contract.encodeABI('blockSettle', [0, 0, '0x'])[:method_hash_length]
        #print('a1 ' + self.campaign_contract.encodeABI('deposit', [37000000000000000000]))
        #print('a2 ' + self.campaign_contract.encodeABI('createChannel', ['some text here', '0x90239420394029034024902', some_valid_address, some_valid_address, 77]))
        #print('a3 ' + self.campaign_contract.encodeABI('settle', [0, 0]))
        #print('b1 ' + self.channel_manager_contract.encodeABI('approve', [0, some_valid_address]))
        #print('b2 ' + self.channel_manager_contract.encodeABI('setBlockPart', [0, 0, '0x']))
        #print('b3 ' + self.channel_manager_contract.encodeABI('setBlockResult', [0, 0, '0x', 0]))
        #print('b4 ' + self.channel_manager_contract.encodeABI('blockSettle', [0, 0, '0x']))

    def current_block(self):
        return self.web3.eth.blockNumber

    ### Main scanner function

    def start(self, block_start, block_limit):
        block_stop = block_start + block_limit
        block_current = self.current_block()
        for block_index in range(block_start, block_stop):
            if block_index > block_current:
                break
            if block_index % 100 == 0:
                print('Scanning transactions at ' + str(block_index) + ' block...')
            block = self.web3.eth.getBlock(block_index, True)
            for transaction in block['transactions']:
                self.handle_transaction(transaction, block['timestamp'])

    ### Handle functions

    def handle_transaction(self, transaction, timestamp):
        if self.is_campaign_deploy(transaction):
            transaction_receipt = self.web3.eth.getTransactionReceipt(transaction['hash'])
            contract_address = transaction_receipt['contractAddress']
            self.campaigns.append(contract_address)
            contract_campaign = self.web3.eth.contract(contract_campaign_abi, contract_address)
            db_id = contract_campaign.call({'from': self.web3.eth.coinbase}).dbId()
            event = ScannerCampaignEvent(transaction, timestamp, contract_address, db_id)
            self.handler.on_campaign_contract_deploy(event)
        elif self.is_campaign_call(transaction):
            self.handle_campaign_call(transaction, timestamp)
        elif self.is_channel_manager_call(transaction):
            self.handle_channel_manager_call(transaction, timestamp)

    def handle_campaign_call(self, transaction, timestamp):
        code = transaction['input']
        method_hash = code[:method_hash_length]
        contract_campaign = self.web3.eth.contract(contract_campaign_abi, transaction['to'])
        db_id = contract_campaign.call({'from': self.web3.eth.coinbase}).dbId()
        campaign_event = ScannerCampaignEvent(transaction, timestamp, transaction['to'], db_id)
        if method_hash == self.campaign_deposit_hash:
            # deposit
            amount = self.read_ether(code, 10)
            self.handler.on_campaign_deposit(campaign_event, amount)
        elif method_hash == self.campaign_withdraw_hash:
            # withdraw
            amount = self.read_ether(code, 10)
            self.handler.on_campaign_withdraw(campaign_event, amount)
        elif method_hash == self.campaign_channel_create_hash:
            # channel create
            channel_manager = contract_campaign.call({'from': self.web3.eth.coinbase}).channelManager()
            channel_index = 0 # TODO
            participants = [] # TODO
            channel_event = ScannerChannelEvent(transaction, timestamp, channel_manager, channel_index, participants)
            self.handler.on_campaign_channel_create(campaign_event, channel_event)
        elif method_hash == self.campaign_channel_settle_hash:
            # channel settle
            channel_manager = contract_campaign.call({'from': self.web3.eth.coinbase}).channelManager()
            channel_index = 0 # TODO
            participants = [] # TODO
            values = [0, 0, 0, 0] # TODO
            channel_settle_event = ScannerChannelSettleEvent(transaction, timestamp, channel_manager, channel_index, participants, values)
            self.handler.on_campaign_channel_settle(campaign_event, channel_settle_event)

    def handle_channel_manager_call(self, transaction, timestamp):
        code = transaction['input']
        method_hash = code[:method_hash_length]
        channel_index = 0 # TODO
        participants = [] # TODO
        channel_event = ScannerChannelEvent(transaction, timestamp, transaction['to'], channel_index, participants)
        if method_hash == self.channel_approve_hash:
            # approve
            validator = '' # TODO
            self.handler.on_channel_approve(channel_event, validator)
        elif method_hash == self.channel_block_part_hash:
            # block part
            block_index = 0 # TODO
            reference = '' # TODO
            self.handler.on_channel_block_part(channel_event, block_index, reference)
        elif method_hash == self.channel_block_result_hash:
            # block result
            block_index = 0 # TODO
            result_hash = '' # TODO
            self.handler.on_channel_block_result(channel_event, block_index, result_hash)
        elif method_hash == self.channel_block_settle:
            # block settle
            block_index = 0 # TODO
            values = [0, 0, 0, 0] # TODO
            channel_settle_event = ScannerChannelSettleEvent(transaction, timestamp, transaction['to'], channel_index, participants, values)
            self.handler.on_channel_block_settle(channel_settle_event, block_index)

    ### Helper detecting functions

    def is_campaign_deploy(self, transaction):
        end_offset = 68 # in characters of hex written binary data (???)
        code = transaction['input']
        if len(code) > len(contract_campaign_bin):
            a = code[:len(contract_campaign_bin)-end_offset]
            b = contract_campaign_bin[:-end_offset]
            return a == b
        return False

    def is_campaign_call(self, transaction):
        return transaction['to'] and transaction['to'].lower() in self.campaigns

    def is_channel_manager_call(self, transaction):
        return transaction['to'] and transaction['to'].lower() in self.channel_managers

    def read_wei(self, string, offset):
        return Web3.toInt(hexstr=string[offset:offset+64])

    def read_ether(self, string, offset):
        return Web3.fromWei(self.read_wei(string, offset), 'ether')

    def read_uint32(self, string, offset):
        return Web3.toInt(hexstr=string[offset:offset+8])