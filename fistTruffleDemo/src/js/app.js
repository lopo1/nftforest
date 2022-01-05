// contract = require("truffle-contract");
App ={
    web3Provider: null,
    contracts: {},
    init: function() {
        return App.initWeb3();
    },
    initWeb3: function() {
        // const Web3 = require('web3');
        if (typeof web3 !=='undefined'){
            App.web3Provider = web3.currentProvider
            web3 = new Web3(App.web3Provider);
        }else{
            App.web3Provider = new Web3.providers.HttpProvider("http://127.0.0.1:7545")
            web3 = new Web3(App.web3Provider);
            console.log("web3 local provider:"+ web3)
        }
        console.log("web3:"+web3)
        App.initContract();
    },
    initContract: function() {
        $.getJSON('../build/contracts/InfoContract.json',function(data){
            App.contracts.InfoContract = TruffleContract(data);
            // App.contracts.InfoContract = MetaCoin.at(data);
            App.contracts.InfoContract.setProvider(App.web3Provider);
            return App.getInfo();
        });
        
    },
    getInfo: function() {
        App.contracts.InfoContract.deployed().then(function(instance){
            return instance.getInfo.call();
        }).then(function(result){
            $("#loader").hide();
            $("#info").html(result[0]+' ('+result[1]+' years old)');
                console.log(result);
        }).catch(function(err){
            console.log(err);
        });
    },
    bindEvents: function() {
        App.contracts.InfoContract.deployed().then(function(instance){
            return instance.setInfo.sendTransaction($("#name").val(),$("#age").val(),{gas:500000});
            // return instance.getInfo.call();
        }).then(function(result){
            App.getInfo();
        }).catch(function(err){
            console.log(err);
        });
        $("#button").click(function() {
            $("#loader").show();
            info.setInfo.sendTransaction($("#name").val(),$("#age").val(),{gas:500000},function(err,result){

            });
        });
    }
}
 $(function(){
    $(window).load(function() {
        App.init();
    });
 });