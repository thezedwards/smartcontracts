class ScannerEvent():
    def __init__(self, transaction, timestamp):
        self.sender = transaction['from']
        self.block_hash = transaction['blockHash']
        self.block_index = transaction['blockNumber']
        self.tx_hash = transaction['hash']
        self.tx_index = transaction['transactionIndex']
        self.timestamp = timestamp
    def __repr__(self):
        return '{}:\n\tSender: {}\n\tBlock hash: {}\n\tBlock number: {}\n\tTx: {}\n\tTimestamp: {}'.format(
            self.__class__.__name__, self.sender, self.block_hash, self.block_index, self.tx_hash, self.timestamp)

class ScannerCampaignEvent(ScannerEvent):
    def __init__(self, transaction, timestamp, campaign, db_id):
        ScannerEvent.__init__(self, transaction, timestamp)
        self.campaign = campaign
        self.db_id = db_id
    def __repr__(self):
        return '{}:\n\tSender: {}\n\tBlock hash: {}\n\tBlock number: {}\n\tTx: {}\n\tTimestamp: {}\n\tCampaign: {}\n\tId: {}'.format(
            self.__class__.__name__, self.sender, self.block_hash, self.block_index, self.tx_hash, self.timestamp, self.campaign, self.db_id)

class ScannerChannelEvent(ScannerEvent):
    def __init__(self, transaction, timestamp, channel_manager, channel_index, participants):
        ScannerEvent.__init__(self, transaction, timestamp)
        self.channel_manager = channel_manager
        self.channel_index = channel_index
        self.participants = participants
    def __repr__(self):
        return '{}:\n\tSender: {}\n\tBlock hash: {}\n\tBlock number: {}\n\tTx: {}\n\tTimestamp: {}\n\tChannel Manager: {}\n\tChannel: {}\n\tParticipants: {}'.format(
            self.__class__.__name__, self.sender, self.block_hash, self.block_index, self.tx_hash, self.timestamp, self.channel_manager, self.channel_index, self.participants)

class ScannerChannelSettleEvent(ScannerChannelEvent):
    def __init__(self, transaction, timestamp, channel_manager, channel_index, participants, values):
        ScannerChannelEvent.__init__(self, transaction, timestamp, channel_manager, channel_index, participants)
        self.ssp_payment = values[0]
        self.auditor_payment = values[1]
        self.total_impressions = values[2]
        self.fraud_impressions = values[3]
    def __repr__(self):
        return '{}:\n\tSender: {}\n\tBlock hash: {}\n\tBlock number: {}\n\tTx: {}\n\tTimestamp: {}\n\tChannel Manager: {}\n\tChannel: {}\n\tParticipants: {}'.format(
            self.__class__.__name__, self.sender, self.block_hash, self.block_index, self.tx_hash, self.timestamp, self.channel_manager, self.channel_index, self.participants)

class ScannerHandler:

    def on_campaign_contract_deploy(self, campaign_event):
        print('[Scanner] on_campaign_contract_deploy')
        print(campaign_event)
        print()
        return

    def on_campaign_deposit(self, campaign_event, amount):
        print('[Scanner] on_campaign_deposit')
        print(campaign_event)
        print(amount)
        print
        return

    def on_campaign_withdraw(self, campaign_event, amount):
        print('[Scanner] on_campaign_withdraw')
        print(campaign_event)
        print(amount)
        print
        return

    def on_campaign_channel_create(self, campaign_event, channel_event):
        print('[Scanner] on_campaign_channel_create')
        print(campaign_event)
        print(channel_event)
        print
        return

    def on_campaign_channel_settle(self, campaign_event, channel_settle_event):
        print('[Scanner] on_campaign_channel_settle')
        print(campaign_event)
        print(channel_settle_event)
        print
        return

    def on_channel_approve(self, channel_event, validator):
        print('[Scanner] on_channel_approve')
        print(channel_event)
        print(validator)
        print
        return

    def on_channel_block_part(self, channel_event, block_index, reference):
        print('[Scanner] on_channel_block_part')
        print(channel_event)
        print(block_index)
        print(reference)
        print
        return

    def on_channel_block_result(self, channel_event, block_index, result_hash):
        print('[Scanner] on_channel_block_result')
        print(channel_event)
        print(block_index)
        print(result_hash)
        print()
        return

    def on_channel_block_settle(self, channel_settle_event, block_index):
        print('[Scanner] on_channel_block_settle')
        print(channel_settle_event)
        print(block_index)
        print
        return

    def on_error(self, message):
        # TODO: it will be very useful to write message to DB
        print('[Scanner] Error: ' + message)