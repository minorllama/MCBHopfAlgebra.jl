import stanza
from nltk.tree import Tree

def uniqued(t):
    assert len(t) == 1
    return t[0]

class TreeBuilder:
    def __init__(self):
        self.nlp_pipeline = stanza.Pipeline('en', processors='tokenize,pos,lemma,depparse,constituency')

class LabelledTree:
    def __init__(self):
        self.index = dict()
        self.n = 0
    def __call__(self, tree):
        if isinstance(tree, Tree):
            # if at leaf, return the label
            if len(tree) == 1 and not isinstance(tree[0], Tree):
                label = uniqued(tree.leaves())
                if not label in self.index:
                    self.index[label] = self.n
                    self.n += 1
                    return self.index[label] 
            offspring = [child for child in tree]
            assert len(offspring) == 2
            return (self.__call__(offspring[0]), self.__call__(offspring[1])) 
        assert False, "unreachable?"
        return "*"

nlp = TreeBuilder()

def tupled_synactic_trees(text, loglevel=0):
    verbose = loglevel > 0
    doc  = nlp.nlp_pipeline(text)
    def tupled_tree(sentence):
        t = Tree.fromstring(str(sentence.constituency))
        t.collapse_unary(collapsePOS=True, collapseRoot=True)
        t.chomsky_normal_form(factor='right', horzMarkov=None, vertMarkov=0, childChar='|', parentChar='^')
        l = LabelledTree()
        tree = l(t)
        if verbose: print(tree)
        return tree

    return [tupled_tree(sentence) for sentence in doc.sentences]
