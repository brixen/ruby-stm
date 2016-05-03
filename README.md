STM for the Ruby language
=========================

Requirements
------------
Gems: parser, unparser.

Supports both MRI>2.1 and Rubinius>3.14.

Usage
-----

First, require ruby_core_ext/proc.rb to extend Proc class with the 'atomic' method.

Send the 'atomic' message to a Proc you want to execute atomically.

To execute atomically and handle a commit conflict use 'atomic\_if\_conflict \&a\_block' 

Also, 'atomic\_retry' is available for automatic retry the transaction on commit conflict.

"Real life" example
-------------------

    require_relative '../ruby_core_ext/proc'
    
    class BankAccount
      def initialize(initial_amount)
        @balance = initial_amount
      end
    
      def deposit(amount)
        new_balance = @balance + amount
        sleep(0.00001) # introduce some disturbance to force thread switch
        @balance = new_balance
      end
    
      def withdraw(amount)
        new_balance = @balance - amount
        sleep(0.00001) # introduce some disturbance to force thread switch
        @balance = new_balance
      end
    
      def transfer_to(amount, another_account)
        withdraw(amount)
        another_account.deposit(amount)
      end
    
      def balance
        @balance
      end
    end
    
    my_account = BankAccount.new(50)
    another_account = BankAccount.new(0)
    
    transfer = Proc.new do
      my_account.transfer_to(1, another_account)
    end
    
    threads = []
    15.times do
      threads << Thread.new do
        transfer.atomic_retry
      end
    end
    
    threads.each { |thread| thread.join }
    
    puts "my_account balance: #{my_account.balance}"
    puts "another_account balance: #{another_account.balance}"
    puts "total money (should be 50): #{(my_account.balance + another_account.balance)}"

Use 'transfer.call' instead of 'transfer.atomic_retry' to execute non-atomically.

Known issues
------------

- Cannot handle multiple procs in a single line (separated by ';').
- Nested transactions are not supported.
- For the moment, atomicity is only guaranteed for instance variables (including class instance variables).