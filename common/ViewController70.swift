/*
 Copyright (c) 2017-present, salesforce.com, inc. All rights reserved.
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import UIKit
import SmartStore

class ViewController: UIViewController {

    let SOUP_NAME = "logSoup";
    let INDICES = SoupIndex.asArraySoupIndexes([["path":"id", "type":"integer"]]);
    
    var counter  : Int = 0;
    var running : Bool = false;
    var store :  SmartStore!;

    @IBOutlet weak var counterLabel: UILabel!
    @IBOutlet weak var startStopButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Database setup
        self.store = SmartStore.sharedGlobal(withName: "global");
        self.store.registerSoup(SOUP_NAME, withIndexSpecs: INDICES);
        
        // Reading counter from db
        self.counter = self.getCurrentCounterFromDb();
    
        // Update UI
        self.updateUI();
    }


    @IBAction func onResetClick(sender: Any) {
        self.running = false;
        self.store.clearSoup(SOUP_NAME);
        self.counter = 0;
        self.updateUI();
    }
    
    @IBAction func onStartStopClick(sender: Any) {
        self.running = !self.running;
        if (self.running) {
            self.startTask();
        }
        self.updateUI();
    }
    
    func updateUI() {
        DispatchQueue.main.async {
            self.startStopButton.setTitle(self.running ? "Stop" : "Start", for: UIControlState.normal);
            self.counterLabel.text = String(self.counter);
        };
    }

    func startTask() {
        DispatchQueue.global(qos: .background).async {
            while (self.running) {
                let currentCounter = self.getCurrentCounterFromDb();
                if (currentCounter == -1) { break; }

                let newCounter = self.insertNext(currentCounter:currentCounter);
                if (newCounter == -1) { break; }

                self.counter = newCounter;
                self.updateUI();
                Thread.sleep(forTimeInterval:0.2);
            }
            self.running = false;
            self.updateUI();
        };
    }
    
    func getCurrentCounterFromDb() -> Int {
        do {
            var result = try self.store.query(using:QuerySpec.buildSmartQuerySpec(smartSql: "SELECT count(*) FROM {\(SOUP_NAME)}", pageSize: 1)!, startingFromPageIndex:0);
            return (result[0] as! [Int])[0];
        }
        catch {
            print("Failed to get count from db");
            return -1;
        }
    }
    
    func insertNext(currentCounter : Int) -> Int {
        let newCounter = currentCounter + 1;
        do {
            try self.store.upsert(entries: [["id": newCounter]], forSoupNamed: self.SOUP_NAME, withExternalIdPath:"id");
            print("Succeeded inserting: \(newCounter)");
            return newCounter;
        }
        catch {
            print("Failed to insert \(newCounter)");
            return -1;
        }
    }
    
}

