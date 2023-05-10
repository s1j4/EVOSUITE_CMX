package org.evosuite.ga.operators.crossover;

import org.evosuite.ga.ConstructionFailedException;
import org.evosuite.testcase.TestChromosome;
import org.evosuite.testsuite.TestSuiteChromosome;

import java.util.ArrayList;
import java.util.Arrays;

public class CompletelyMappedCrossover extends CrossOverFunction<TestSuiteChromosome> {
    @Override
    public void crossOver(TestSuiteChromosome parent1, TestSuiteChromosome parent2) throws ConstructionFailedException {

        ArrayList<TestChromosome> c1 = new ArrayList<>();
        ArrayList<TestChromosome> c2 = new ArrayList<>();

        TestChromosome initial = null;
        TestChromosome A = null;
        TestChromosome B = null;
        TestChromosome C = new TestChromosome();

        boolean foundA = false;
        boolean foundB = false;
        boolean foundC = false;

        //Limits the scope of search to the shorter suite
        int length = Math.min(parent1.size(), parent2.size());

        try {

            int i;

            //Step 1 - Finds first unequal TestChromosome of parent1 & parent2, which is set to TestChromosome A.
            for (i = 0; i < length; i++) {
                if (!parent1.getTestChromosome(i).equals(parent2.getTestChromosome(i))) {
                    initial = parent1.getTestChromosome(i);
                    A = parent2.getTestChromosome(i);
                    c1.add(A);
                    break;
                }
            }

            if(initial == null || A == null) {
                throw new ConstructionFailedException("Initial or A was not set");
            }

            while (!C.equals(initial)) {//Step 4 - Repeats step 2 & 3

                //Step 2a - Finds TestChromosome B in parent2, which is parallel to TestChromosome A in parent1.
                for (i = 0; i < length; i++) {
                    if (A.equals(parent1.getTestChromosome(i))) {
                        B = parent2.getTestChromosome(i);
                        foundB = true;
                        break;
                    }
                }

                if(foundB) {foundB = false;} else {throw new ConstructionFailedException("B Not found");}

                //Step 2b - Finds TestChromosome C in parent2, which is parallel to TestChromosome B in parent1.
                for (i = 0; i < length; i++) {
                    if (B.equals(parent1.getTestChromosome(i))) {
                        C = parent2.getTestChromosome(i);
                        c2.add(C);
                        foundC = true;
                        break;
                    }
                }

                if(foundC) {foundC = false;} else {throw new ConstructionFailedException("C Not found");}

                //Step 3 - Finds TestChromosome A in parent2, which is parallel to TestChromosome C in parent1.
                for (i = 0; i < length; i++) {
                    if (C.equals(parent1.getTestChromosome(i))) {
                        if (!C.equals(initial)) {
                            c1.add(parent2.getTestChromosome(i));
                        }
                        A = parent2.getTestChromosome(i);
                        foundA = true;
                        break;
                    }
                }

                if(foundA) {foundA = false;} else {throw new ConstructionFailedException("A not found");}

            }

            //Confirm elements of c1 & c2 are the same
            if(!c1.containsAll(c2)) {
                throw new ConstructionFailedException("c1 & c2 not equal");
            }


            //Step 5

            //.toArray to prevent re-indexing on removal
            TestChromosome[] offspring1Array = parent1.getTestChromosomes().toArray(new TestChromosome[parent1.size()]);
            TestChromosome[] offspring2Array = parent2.getTestChromosomes().toArray(new TestChromosome[parent2.size()]);

            //Copies to use for iteration
            TestChromosome[] copyOffspring1Array = Arrays.copyOf(offspring1Array, offspring1Array.length);
            TestChromosome[] copyOffspring2Array = Arrays.copyOf(offspring2Array, offspring2Array.length);

            //Remove contents of c1 or c2 from offspring1Array
            for(i = 0; i < copyOffspring1Array.length; i++) {
                for(int j = 0; j < c2.size(); j++) {
                    if(copyOffspring1Array[i].equals(c2.get(j))) {
                        offspring1Array[i] = null;
                        break;
                    }
                }
            }

            //Remove contents of c1 or c2 from offspring2Array
            for(i = 0; i < copyOffspring2Array.length; i++) {
                for(int j = 0; j < c2.size(); j++) {
                    if(copyOffspring2Array[i].equals(c2.get(j))) {
                        offspring2Array[i] = null;
                        break;
                    }
                }
            }


            //Step 6 & 7

            TestSuiteChromosome offspring1 = new TestSuiteChromosome();
            TestSuiteChromosome offspring2 = new TestSuiteChromosome();

            //Build offspring1 by taking elements from c2
            for(i = 0; i < copyOffspring1Array.length; i++) {
                if(offspring1Array[i] == null) {
                    offspring1Array[i] = c2.get(0);
                    c2.remove(0);
                    if(c2.isEmpty()) {
                        break;
                    }
                }
            }

            for(i = 0; i < offspring1Array.length; i++) {
                offspring1.addTestChromosome(offspring1Array[i]);
            }

            parent1.replaceWithTestChromosomes(offspring1.getTestChromosomes());

            //Build offspring2 by taking elements from c1
            for(i = 0; i < copyOffspring2Array.length; i++) {
                if(offspring2Array[i] == null) {
                    offspring2Array[i] = c1.get(0);
                    c1.remove(0);
                    if(c1.isEmpty()) {
                        break;
                    }
                }
            }

            for(i = 0; i < offspring2Array.length; i++) {
                offspring2.addTestChromosome(offspring2Array[i]);
            }

            parent2.replaceWithTestChromosomes(offspring2.getTestChromosomes());

        }
        catch (NullPointerException e) {
            throw new ConstructionFailedException("FOUND NULLPOINTER AT: " + e);
        }
    }
}



