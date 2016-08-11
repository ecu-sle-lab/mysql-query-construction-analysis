module QCPAnalysis::QCPCorpus

import lang::php::util::Corpus;
import lang::php::util::Utils;
import lang::php::ast::AbstractSyntax;
import lang::php::ast::System;
import lang::php::analysis::cfg::CFG;
import lang::php::analysis::cfg::BuildCFG;

import Node;
import ValueIO;

loc cfgLoc = |project://QCPAnalysis/cfgs|;

private Corpus corpus = ( 
	"faqforge" : "1.3.2",
	"geccBBlite" : "0.1",
	"Schoolmate" : "1.5.4",
	"WebChess" : "0.9.0"
	);
	
public Corpus getCorpus() = corpus;

public void buildCorpus() {
	for (p <- corpus, v := corpus[p]) {
		buildBinaries(p,v);
	}
}

public rel[str exprType, loc useLoc] exprTypesAndLocsInCorpus() {
	rel[str exprType, loc useLoc] res = { };
	for (p <- corpus, v := corpus[p]) {
		pt = loadBinary(p,v);
		
		// Get all the calls to mysql_query
		queriesRel = { < c, c@at > | /c:call(name(name("mysql_query")),_) := pt };
		
		// Extract out all the parameters
		params = { pi | c <- queriesRel<0>, pi <- c.parameters };
		
		// Find all the expression node names used in any of the parameters
		res = res + { < getName(e), e@at > | /Expr e := params };
	}
	
	return res;
}

public set[str] exprTypesInCorpus() = exprTypesAndLocsInCorpus()<0>;

public set[Script] scriptsWithExprType(str exprType){
	set[Script] res = {};
	for (p <- corpus, v := corpus[p]){
		pt = loadBinary(p,v);
		for(l <- pt.files, scr := pt.files[l]){
			calls = {c | /c:call(name(name("mysql_query")),_) := scr};
			params = { pi | c <- calls, pi <- c.parameters};
			exprTypes = {getName(e) | /Expr e := params};
			if(exprType in exprTypes)
				res += scr;
		}
	}
	return res;
}

public void buildCFGsCorpus(){
	Corpus corpus = getCorpus();
	for(p <- corpus, v := corpus[p]){
		pt = loadBinary(p, v);
		cfgs = {m | scr <- pt.files, m := buildCFGs(scr)};
		writeBinaryValueFile(cfgLoc + "<p>_<v>.cfgmaps", cfgs, compression = false);
	}
}